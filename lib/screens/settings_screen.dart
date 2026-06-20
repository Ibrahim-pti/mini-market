import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ئاسایش (Security)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'پاراستنی سیستەمەکە بە ناوی بەکارهێنەر و پاسوۆرد',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 28),
                _buildSecuritySection(context, isDesktop),
              ],
            ),
          ),
        ));
  }

  Widget _buildSecuritySection(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        bool hasCredentials = auth.username != null &&
            auth.username!.isNotEmpty &&
            auth.password != null &&
            auth.password!.isNotEmpty;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            if (!hasCredentials)
              _SettingsCard(
                width: isDesktop ? 400 : double.infinity,
                icon: Icons.lock_outline_rounded,
                color: AppColors.primary,
                title: 'دانانی هەژمار',
                description:
                    'ناوی بەکارهێنەر و پاسوۆردێک دابنێ بۆ ئەوەی کەس نەتوانێت بچێتە ناو ئەپەکەت.',
                buttonLabel: 'دانانی هەژمار',
                buttonIcon: Icons.person_add_rounded,
                buttonColor: AppColors.primary,
                glowColor: AppColors.primary,
                onPressed: () =>
                    _showCredentialsDialog(context, auth, isSetting: true),
              )
            else ...[
              _SettingsCard(
                width: isDesktop ? 400 : double.infinity,
                icon: Icons.lock_reset_rounded,
                color: AppColors.primary,
                title: 'گۆڕینی هەژمار',
                description:
                    'ناوی بەکارهێنەر و پاسوۆردەکە بگۆڕە بۆ هەژمارێکی نوێ.',
                buttonLabel: 'گۆڕینی هەژمار',
                buttonIcon: Icons.edit_rounded,
                buttonColor: AppColors.primary,
                glowColor: AppColors.primary,
                onPressed: () =>
                    _showCredentialsDialog(context, auth, isSetting: true),
              ),
              _SettingsCard(
                width: isDesktop ? 400 : double.infinity,
                icon: Icons.no_encryption_rounded,
                color: AppColors.rose,
                title: 'لابردنی پاسوۆرد',
                description:
                    'ئەمە وادەکات ئەپەکە ڕاستەوخۆ بکرێتەوە بەبێ هیچ هەژمارێک.',
                buttonLabel: 'لابردنی هەژمار',
                buttonIcon: Icons.delete_forever_rounded,
                buttonColor: AppColors.rose,
                glowColor: AppColors.rose,
                onPressed: () =>
                    _showCredentialsDialog(context, auth, isSetting: false),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showCredentialsDialog(
    BuildContext context,
    AuthProvider auth, {
    required bool isSetting,
  }) {
    TextEditingController userController = TextEditingController();
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isSetting
              ? 'زانیاری هەژماری نوێ بنووسە'
              : 'دڵنیایت لە سڕینەوەی هەژمار؟',
        ),
        content: isSetting
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'ناوی بەکارهێنەر',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'پاسوۆرد',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              )
            : Text(
                'گەر هەژمار بسڕیتەوە، هەرکەسێک دەتوانێت بچێتە ناو ئەپەکەت بەبێ پاسوۆرد.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'پاشگەزبوونەوە',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isSetting) {
                if (userController.text.isNotEmpty &&
                    passController.text.isNotEmpty) {
                  await auth.setCredentials(
                      userController.text, passController.text);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('هەژمار بە سەرکەوتوویی دانرا'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('تکایە هەردوو خانەکە پڕبکەوە'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                await auth.removeCredentials();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('هەژمار بە سەرکەوتوویی سڕایەوە'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSetting ? AppColors.primary : AppColors.rose,
            ),
            child: Text(isSetting ? 'پەسەندکردن' : 'بەڵێ، سڕینەوە'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final Color buttonColor;
  final Color glowColor;
  final VoidCallback onPressed;
  const _SettingsCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.buttonColor,
    required this.glowColor,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                color: AppColors.inkSoft,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(buttonIcon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        buttonLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
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
