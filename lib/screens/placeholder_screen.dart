import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Generic placeholder for sections that are not implemented yet.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, this.title = 'بەشێک'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              '$title بەم زووانە ئامادە دەبێت',
              style: TextStyle(
                color: AppColors.inkSoft,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
