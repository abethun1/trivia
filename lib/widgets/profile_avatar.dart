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

  Color blendWithWhite(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  Color blendWithBlack(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  Widget avatarFrame({required Widget child, required Color accent}) {
    final outerLight = blendWithWhite(accent, 0.42);
    final outerDark = blendWithBlack(accent, 0.08);

    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              outerLight,
              accent,
              outerDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.38),
              blurRadius: widget.radius * 0.36,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blendWithWhite(accent, 0.7),
            ),
            child: ClipOval(child: child),
          ),
        ),
      ),
    );
  }

  Widget initialAvatar() {
    final initial = initialFromUsername(widget.username);
    final accent = parseHexColor(widget.avatarColorHex);
    final fallbackBg = blendWithWhite(accent, 0.62);
    final textColor = fallbackBg.computeLuminance() > 0.55
        ? const Color(0xFF2A3650)
        : Colors.white;

    return avatarFrame(
      accent: accent,
      child: Container(
        color: fallbackBg,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: widget.radius * 0.75,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = parseHexColor(widget.avatarColorHex);

    if (loadingUrl) {
      return avatarFrame(
        accent: accent,
        child: Container(
          color: blendWithWhite(accent, 0.62),
          alignment: Alignment.center,
          child: SizedBox(
            width: widget.radius * 0.8,
            height: widget.radius * 0.8,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (imageUrl == null) {
      return initialAvatar();
    }

    return avatarFrame(
      accent: accent,
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                imageUrl = null;
              });
            });
          }
          return Container(
            color: blendWithWhite(accent, 0.62),
          );
        },
      ),
    );
  }
}
