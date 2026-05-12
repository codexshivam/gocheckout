import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class ImageSquare extends StatelessWidget {
  const ImageSquare({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: kRadiusSmall,
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 10))),
    );
  }
}
