import 'package:flutter/material.dart';

import '../app_styles.dart';

class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: inputDecoration(label),
    );
  }
}
