import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/storage_buckets.dart';

class ProfileAvatar extends StatefulWidget {
  final String username;
  final String? avatarPath;
  final String avatarStatus;
  final String avatarColorHex;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.username,
    required this.avatarPath,
    required this.avatarStatus,
    required this.avatarColorHex,
    this.radius = 38,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? imageUrl;
  bool loadingUrl = false;

  @override
  void initState() {
    super.initState();
    resolveImageUrl();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath ||
        oldWidget.avatarStatus != widget.avatarStatus) {
      resolveImageUrl();
    }
  }

  Future<void> resolveImageUrl() async {
    final path = widget.avatarPath?.trim();
    final isApproved = widget.avatarStatus.toLowerCase() == 'approved';
    if (path == null || path.isEmpty || !isApproved) {
      if (!mounted) return;
      setState(() {
        imageUrl = null;
        loadingUrl = false;
      });
      return;
    }

    setState(() {
      loadingUrl = true;
    });

    final storage = Supabase.instance.client.storage.from(avatarsBucketName);
    try {
      final signedUrl = await storage.createSignedUrl(path, 60 * 60);
      if (!mounted) return;
      setState(() {
        imageUrl = signedUrl;
        loadingUrl = false;
      });
      return;
    } catch (_) {
      try {
        final publicUrl = storage.getPublicUrl(path);
        if (!mounted) return;
        setState(() {
          imageUrl = publicUrl;
          loadingUrl = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          imageUrl = null;
          loadingUrl = false;
        });
      }
    }
  }

  Color parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) {
      return const Color(0xFFD8B4FE);
    }
    final value = int.tryParse(clean, radix: 16);
    if (value == null) {
      return const Color(0xFFD8B4FE);
    }
    return Color(0xFF000000 | value);
  }

  String initialFromUsername(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed[0].toUpperCase();
  }

  Widget initialAvatar() {
    final initial = initialFromUsername(widget.username);
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: parseHexColor(widget.avatarColorHex),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.radius * 0.8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingUrl) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: parseHexColor(widget.avatarColorHex),
        child: SizedBox(
          width: widget.radius * 0.8,
          height: widget.radius * 0.8,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (imageUrl == null) {
      return initialAvatar();
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: parseHexColor(widget.avatarColorHex),
      backgroundImage: NetworkImage(imageUrl!),
      onBackgroundImageError: (_, _) {
        if (!mounted) return;
        setState(() {
          imageUrl = null;
        });
      },
      child: const SizedBox.shrink(),
    );
  }
}
