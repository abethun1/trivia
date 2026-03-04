import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/storage_buckets.dart';
import '../main.dart';
import '../models/user_profile.dart';
import '../widgets/profile_avatar.dart';
import 'avatar_color_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const SettingsScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile profile;
  bool avatarBusy = false;
  bool displayNameBusy = false;

  @override
  void initState() {
    super.initState();
    profile = widget.userProfile;
  }

  Future<void> signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
    );
  }

  Widget buildButton({required String text, required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Future<void> showAvatarChoiceDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Avatar"),
          content: const Text("Choose how to update your avatar."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, "color"),
              child: const Text("Change Color"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, "upload"),
              child: const Text("Upload Image"),
            ),
          ],
        );
      },
    );

    if (choice == "color") {
      await handleChangeColor();
    } else if (choice == "upload") {
      await handleUploadAvatar();
    }
  }

  Future<bool> usernameTaken(String username, {String? excludeUserId}) async {
    final client = Supabase.instance.client;
    final normalized = username.trim();
    final result = await client
        .from('user_profiles')
        .select('id')
        .ilike('username', normalized)
        .limit(1);

    if (excludeUserId == null) {
      return result.isNotEmpty;
    }

    final remaining = result
        .where((row) => (row['id'] as String?) != excludeUserId)
        .toList();

    return remaining.isNotEmpty;
  }

  Future<void> handleChangeDisplayName() async {
    final controller = TextEditingController(text: profile.username);

    final nextName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Enter New Name"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (nextName == null) {
      return;
    }

    if (nextName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username cannot be empty.")),
      );
      return;
    }

    if (nextName == profile.username) {
      return;
    }

    setState(() {
      displayNameBusy = true;
    });

    try {
      final taken = await usernameTaken(nextName, excludeUserId: profile.id);
      if (taken) {
        if (!mounted) return;
        setState(() {
          displayNameBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username is already taken.")),
        );
        return;
      }

      await Supabase.instance.client.from('user_profiles').update({
        'username': nextName,
      }).eq('id', profile.id);

      if (!mounted) return;
      setState(() {
        profile = profile.copyWith(username: nextName);
        displayNameBusy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Display name updated.")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        displayNameBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Display name update failed: $e")),
      );
    }
  }

  Future<void> handleChangeColor() async {
    final selectedHex = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarColorScreen(
          username: profile.username,
          initialColorHex: profile.avatarColorHex,
        ),
      ),
    );

    if (selectedHex == null || selectedHex == profile.avatarColorHex) {
      return;
    }

    setState(() {
      avatarBusy = true;
    });

    final updatedProfile = profile.copyWith(avatarColorHex: selectedHex);
    setState(() {
      profile = updatedProfile;
    });

    try {
      final client = Supabase.instance.client;
      await client.from('user_profiles').update({
        'avatar_color_hex': selectedHex,
        'avatar_status': 'approved',
      }).eq('id', profile.id);

      if (!mounted) return;
      setState(() {
        avatarBusy = false;
      });

      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        avatarBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Avatar color update failed: $e")),
      );
    }
  }

  String extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) {
      return 'jpg';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  String contentTypeFromExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> handleUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    Uint8List? bytes = picked.bytes;
    if (bytes == null && !kIsWeb && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not read selected file bytes.")),
      );
      return;
    }

    final ext = extensionFromName(picked.name);
    final contentType = contentTypeFromExtension(ext);
    final userId = profile.id;
    final path = "pending/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext";

    setState(() {
      avatarBusy = true;
    });

    try {
      final client = Supabase.instance.client;

      await client.storage.from(avatarsBucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      await client.from('user_profiles').update({
        'avatar_pending_path': path,
        'avatar_status': 'pending',
      }).eq('id', userId);

      if (!mounted) return;

      setState(() {
        profile = profile.copyWith(
          avatarPendingPath: path,
          avatarStatus: 'pending',
        );
        avatarBusy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Avatar uploaded and pending review."),
        ),
      );

      Navigator.pop(context, profile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        avatarBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Avatar upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ProfileAvatar(
              username: profile.username,
              avatarPath: profile.avatarPath,
              avatarStatus: profile.avatarStatus,
              avatarColorHex: profile.avatarColorHex,
              radius: 44,
            ),
            const SizedBox(height: 10),
            if (profile.avatarStatus.toLowerCase() == 'pending')
              const Text(
                "Avatar review pending. Current avatar stays as color.",
                style: TextStyle(fontSize: 12),
              ),
            buildButton(
              text: displayNameBusy ? "Updating Name..." : "Change Display Name",
              onPressed: displayNameBusy ? null : handleChangeDisplayName,
            ),
            buildButton(
              text: avatarBusy ? "Updating Avatar..." : "Change Avatar Pic",
              onPressed: avatarBusy ? null : showAvatarChoiceDialog,
            ),
            const Spacer(),
            buildButton(
              text: "Sign Out",
              onPressed: () => signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
