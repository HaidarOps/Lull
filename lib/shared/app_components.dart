import 'package:flutter/material.dart';

import 'app_layout.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.child,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppLayout.primaryButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: const Color(0xFFE0E1E1),
          disabledForegroundColor: const Color(0xFF7A848B),
          backgroundColor: const Color(0xFF2F3E49),
          foregroundColor: Colors.white,
          elevation: onPressed == null ? 0 : 10,
          shadowColor: const Color(0x332F3E49),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child:
            child ??
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
      ),
    );
  }
}

class AppOptionPill extends StatelessWidget {
  const AppOptionPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.fontSize,
    required this.onTap,
    this.height = AppLayout.pillHeight,
  });

  final String label;
  final bool isSelected;
  final double fontSize;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFEAF1F5) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? const Color(0xFF6F8796) : const Color(0xFFDADDDD),
          width: isSelected ? 1.4 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: height,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF53616B),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
