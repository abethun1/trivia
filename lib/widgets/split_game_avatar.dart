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

  @override
  Widget build(BuildContext context) {
    final leftColor = parseHexColor(widget.topLeftPlayer.avatarColorHex);
    final rightColor = parseHexColor(widget.bottomRightPlayer.avatarColorHex);
    final leftInitial = initial(widget.topLeftPlayer.username);
    final rightInitial = initial(widget.bottomRightPlayer.username);

    return SizedBox(
      width: widget.size,
      height: widget.size,
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
                            errorBuilder: (_, _, _) => Container(color: leftColor),
                          )
                        : Container(color: leftColor),
                  ),
                ),
                Positioned.fill(
                  child: ClipPath(
                    clipper: _BottomRightHalfClipper(),
                    child: bottomRightUrl != null
                        ? Image.network(
                            bottomRightUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(color: rightColor),
                          )
                        : Container(color: rightColor),
                  ),
                ),
                if (topLeftUrl == null)
                  Align(
                    alignment: const Alignment(-0.35, -0.35),
                    child: Text(
                      leftInitial,
                      style: TextStyle(
                        fontSize: widget.size * 0.42,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
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
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SplitOutlinePainter(),
            ),
          ),
        ],
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

class _SplitOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 0.8;
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    final circlePath = Path()..addOval(circleRect);

    final borderPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.black45
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipPath(circlePath);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      linePaint,
    );
    canvas.restore();

    canvas.drawOval(circleRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
