import 'package:flutter/material.dart';

class DashboardStyles {
  // COLORS
  static const Color primaryRed = Color.fromARGB(255, 1, 1, 19);
  static const Color cardBackground = Color.fromARGB(255, 49, 207, 43);

  // TEXT STYLES
  static const TextStyle statsText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle gameCircleText = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  // DECORATIONS
  static final BoxDecoration statsCardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        blurRadius: 6,
        offset: Offset(0, 3),
        color: Colors.black26,
      )
    ],
  );

  static final BoxDecoration gameCircleDecoration = BoxDecoration(
    color: const Color.fromARGB(255, 71, 33, 209),
    shape: BoxShape.circle,
  );

  // BUTTON STYLES
  static final ButtonStyle startGameButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  // SIZES / PADDING
  static const double gameCircleSize = 70;
  static const EdgeInsets gameCirclePadding =
      EdgeInsets.symmetric(horizontal: 8);
}
