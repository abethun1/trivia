import 'package:flutter/material.dart';

// Adjust this value to control how strong the background appears.
const double appBackgroundOverlayOpacity = 0.28;

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/app_background.png",
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: appBackgroundOverlayOpacity),
          ),
        ),
        child,
      ],
    );
  }
}
