import 'package:flutter/material.dart';

class LoginStyles
{
  static const TextStyle headerText = TextStyle
  (
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const BoxConstraints cardConstraints = BoxConstraints
  (
    maxWidth: 400,
  );



  static ButtonStyle mainButtonStyle = ElevatedButton.styleFrom
  (
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder
    (
      borderRadius: BorderRadius.circular(30),
    ),
  );

  static BoxDecoration fieldContainerDecoration = BoxDecoration
  (
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const
    [
      BoxShadow
      (
        blurRadius: 6,
        color: Colors.black12,
        offset: Offset(0, 3),
      ),
    ],
  );

  static InputDecoration inputDecoration(String label)
  {
    return InputDecoration
    (
      labelText: label,
      border: OutlineInputBorder
      (
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
