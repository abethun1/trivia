import 'package:flutter/material.dart';

class QuestionStyles {
  static const backgroundColor = Color(0xFFF2F2F2);

  static const questionTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final questionCardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  static const answerTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final answerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );

  static const timerTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const timerBackgroundColor = Color.fromARGB(255, 253, 252, 252);

  static const timerColor = Colors.red;
}