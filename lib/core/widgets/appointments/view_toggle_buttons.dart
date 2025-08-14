import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class ViewToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const ViewToggleButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent, 
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: kFontSizeRegular - 2,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, 
          ),
        ),
      ),
    );
  }
}
