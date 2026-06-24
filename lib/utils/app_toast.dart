import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, info }

/// پەیامی شناوەری یەکگرتوو بۆ هەموو پەیجەکانی ئەپ.
void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  final Color color;
  final IconData icon;
  switch (type) {
    case ToastType.success:
      color = AppColors.emerald;
      icon = Icons.check_circle_rounded;
      break;
    case ToastType.error:
      color = AppColors.rose;
      icon = Icons.error_rounded;
      break;
    case ToastType.info:
      color = AppColors.ink;
      icon = Icons.info_rounded;
      break;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
