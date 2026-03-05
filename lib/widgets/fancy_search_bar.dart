import 'package:flutter/material.dart';

class FancySearchBar extends StatelessWidget
{
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final EdgeInsetsGeometry? margin;

  const FancySearchBar
  (
    {
      super.key,
      required this.controller,
      required this.hintText,
      this.onChanged,
      this.margin,
    }
  );

  @override
  Widget build(BuildContext context)
  {
    return Container
    (
      margin: margin,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration
      (
        borderRadius: BorderRadius.circular(60),
        gradient: const LinearGradient
        (
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
          [
            Color(0xFFEFF4FF),
            Color(0xFFD8E6FF),
            Color(0xFF8FB7FF),
          ],
        ),
        boxShadow:
        [
          BoxShadow
          (
            color: const Color(0xFF4A7FE5).withValues(alpha: 0.45),
            offset: const Offset(0, 10),
            blurRadius: 16,
          ),
        ],
      ),
      child: Container
      (
        height: 60,
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration
        (
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFBED2F8), width: 5),
          boxShadow:
          [
            BoxShadow
            (
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row
        (
          children:
          [
            Container
            (
              width: 45,
              height: 45,
              decoration: BoxDecoration
              (
                shape: BoxShape.circle,
                gradient: const LinearGradient
                (
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                  [
                    Color(0xFF6CD0FF),
                    Color(0xFF309AFF),
                  ],
                ),
                border: Border.all(color: const Color(0xFF2E7CDB), width: 2),
                boxShadow:
                [
                  BoxShadow
                  (
                    color: const Color(0xFF2E70D6).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded
            (
              child: TextField
              (
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle
                (
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7A9FE0),
                ),
                decoration: InputDecoration
                (
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: const TextStyle
                  (
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A9FE0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
