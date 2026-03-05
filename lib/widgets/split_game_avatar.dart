import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/storage_buckets.dart';
import '../models/user_profile.dart';

class SplitGameAvatar extends StatefulWidget {
  final UserProfile topLeftPlayer;
  final UserProfile bottomRightPlayer;
  final double size;

  const SplitGameAvatar({
    super.key,
    required this.topLeftPlayer,
    required this.bottomRightPlayer,
    this.size = 76,
  });

  @override
  State<SplitGameAvatar> createState() => _SplitGameAvatarState();
}

class _SplitGameAvatarState extends State<SplitGameAvatar> {
  String? topLeftUrl;
  String? bottomRightUrl;

  @override
  void initState() {
    super.initState();
    resolveUrls();
  }

  @override
  void didUpdateWidget(covariant SplitGameAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topLeftPlayer.avatarPath != widget.topLeftPlayer.avatarPath ||
        oldWidget.topLeftPlayer.avatarStatus != widget.topLeftPlayer.avatarStatus ||
        oldWidget.bottomRightPlayer.avatarPath != widget.bottomRightPlayer.avatarPath ||
        oldWidget.bottomRightPlayer.avatarStatus != widget.bottomRightPlayer.avatarStatus) {
      resolveUrls();
    }
  }

  Future<String?> resolveAvatarUrl(UserProfile user) async {
    final path = user.avatarPath?.trim();
    final approved = user.avatarStatus.toLowerCase() == 'approved';
    if (path == null || path.isEmpty || !approved) {
      return null;
    }

    final storage = Supabase.instance.client.storage.from(avatarsBucketName);
    try {
      return await storage.createSignedUrl(path, 60 * 60);
    } catch (_) {
      try {
        return storage.getPublicUrl(path);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> resolveUrls() async {
    final left = await resolveAvatarUrl(widget.topLeftPlayer);
    final right = await resolveAvatarUrl(widget.bottomRightPlayer);
    if (!mounted) return;
    setState(() {
      topLeftUrl = left;
      bottomRightUrl = right;
    });
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

  String initial(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Color blendWithWhite(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  Color blendWithBlack(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  Color average(Color a, Color b) {
    return Color.fromARGB(
      255,
      ((a.r + b.r) / 2).round(),
      ((a.g + b.g) / 2).round(),
      ((a.b + b.b) / 2).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftColor = parseHexColor(widget.topLeftPlayer.avatarColorHex);
    final rightColor = parseHexColor(widget.bottomRightPlayer.avatarColorHex);
    final accent = average(leftColor, rightColor);
    final leftInitial = initial(widget.topLeftPlayer.username);
    final rightInitial = initial(widget.bottomRightPlayer.username);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              blendWithWhite(leftColor, 0.42),
              leftColor,
              blendWithWhite(rightColor, 0.42),
              rightColor,
              blendWithWhite(leftColor, 0.42),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: widget.size * 0.22,
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
            child: Stack(
              children: [
                ClipOval(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipPath(
                          clipper: _TopLeftHalfClipper(),
                          child: topLeftUrl != null
                              ? Image.network(
                                  topLeftUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: blendWithWhite(leftColor, 0.62),
                                  ),
                                )
                              : Container(color: blendWithWhite(leftColor, 0.62)),
                        ),
                      ),
                      Positioned.fill(
                        child: ClipPath(
                          clipper: _BottomRightHalfClipper(),
                          child: bottomRightUrl != null
                              ? Image.network(
                                  bottomRightUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: blendWithWhite(rightColor, 0.62),
                                  ),
                                )
                              : Container(color: blendWithWhite(rightColor, 0.62)),
                        ),
                      ),
                      if (topLeftUrl == null)
                        Align(
                          alignment: const Alignment(-0.35, -0.35),
                          child: Text(
                            leftInitial,
                            style: TextStyle(
                              fontSize: widget.size * 0.42,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2A3650),
                            ),
                          ),
                        ),
                      if (bottomRightUrl == null)
                        Align(
                          alignment: const Alignment(0.35, 0.35),
                          child: Text(
                            rightInitial,
                            style: TextStyle(
                              fontSize: widget.size * 0.42,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2A3650),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SplitDiagonalPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopLeftHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomRightHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SplitDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF5F7FB8).withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(clipPath);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      linePaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
