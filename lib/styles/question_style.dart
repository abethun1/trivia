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
    backgroundColor: const Color(0xFFF2F6FF),
    foregroundColor: const Color(0xFF0E49A8),
    elevation: 8,
    shadowColor: const Color(0x663B74D8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
      side: const BorderSide(
        color: Color(0xFFBCD2FF),
        width: 2,
      ),
    ),
  );

  static const timerTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0E49A8),
    shadows: [
      Shadow(
        color: Color.fromARGB(90, 9, 57, 138),
        offset: Offset(0, 1),
        blurRadius: 1,
      ),
    ],
  );

  static const timerBackgroundColor = Color(0xFFDCE8FF);

  static const timerColor = Color(0xFF0E49A8);

  static final timerContainerDecoration = BoxDecoration(
    color: const Color(0xFFF2F6FF),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: const Color(0xFFBCD2FF),
      width: 2,
    ),
    boxShadow: const [
      BoxShadow(
        color: Color(0x663B74D8),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );
}
