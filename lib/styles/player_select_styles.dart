import 'package:flutter/material.dart';

class PlayerSelectStyles
{
  static const EdgeInsets screenPadding =
      EdgeInsets.all(24);

  static const double cardBorderRadius = 16;

  static const BoxDecoration playerCardDecoration =
      BoxDecoration
      (
        color: Colors.white,
        borderRadius: BorderRadius.all
        (
          Radius.circular(cardBorderRadius),
        ),
        boxShadow:
        [
          BoxShadow
          (
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      );

  static const EdgeInsets playerCardMargin =
      EdgeInsets.symmetric(vertical: 8);

  static const EdgeInsets playerCardPadding =
      EdgeInsets.all(16);

  static const TextStyle playerInputTextStyle =
      TextStyle
      (
        fontSize: 20,
      );

  static const InputDecoration playerInputDecoration =
      InputDecoration
      (
        border: InputBorder.none,
      );

  static const SizedBox verticalSpacingLarge =
      SizedBox(height: 24);

  static const SizedBox verticalSpacingSmall =
      SizedBox(height: 12);

  static const SizedBox verticalSpacingTiny =
      SizedBox(height: 8);


  static ButtonStyle nextButtonStyle =
      ElevatedButton.styleFrom
      (
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder
        (
          borderRadius: BorderRadius.circular(20),
        ),
      );
}
