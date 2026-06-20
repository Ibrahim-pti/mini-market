import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/excel_service.dart';
import '../services/backup_service.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ڕێکخستن و باکەپ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'بەڕێوەبردنی داتا و پاراستنی زانیاریەکانت',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _SettingsCard(
                  width: isDesktop ? 400 : double.infinity,
                  icon: Icons.cloud_upload_rounded,
                  color: AppColors.sky,
                  title: 'باکەپ (Backup)',
                  description:
                      'کۆپییەکی داتاکانت هەڵبگرە لە شوێنێکی دیاریکراو (وەک USB) بۆ ئەوەی لە فەوتان بیانپارێزیت. سەرباری ئەمە، ئەپەکە ڕۆژانە دوو جار خۆکارانە باکەپ هەڵدەگرێت.',
                  buttonLabel: 'وەرگرتنی باکەپ',
                  buttonIcon: Icons.backup_rounded,
                  buttonColor: AppColors.sky,
                  glowColor: AppColors.sky,
                  onPressed: () async {
                    bool success = await provider.backupDatabase();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'باکەپ بە سەرکەوتوویی گیرا'
                                : 'هەڵەیەک ڕوویدا لە کاتی باکەپگرتن',
                          ),
                          backgroundColor: success
                              ? AppColors.emerald
                              : AppColors.rose,
                        ),
                      );
                    }
                  },
                ),
                _SettingsCard(
                  width: isDesktop ? 400 : double.infinity,
                  icon: Icons.settings_backup_restore_rounded,
                  color: AppColors.amber,
                  title: 'هێنانەوە (Restore)',
                  description:
                      'فایلی باکەپەکەت بهێنەرەوە بۆ ئەوەی داتاکانت بگەڕێنیتەوە. (ئەمە داتای ئێستا دەسڕێتەوە)',
                  buttonLabel: 'هێنانەوەی باکەپ',
                  buttonIcon: Icons.restore_rounded,
                  buttonColor: AppColors.amber,
                  glowColor: AppColors.amber,
                  onPressed: () async {
                    bool confirm =
                        await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.amber,
                                ),
                                SizedBox(width: 10),
                                Text('دڵنیایت؟'),
                              ],
                            ),
                            content: Text(
                              'هێنانەوەی باکەپ داتاکانی ئێستات دەسڕێتەوە و داتاکانی ناو باکەپەکە جێگەی دەگرێتەوە.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'نەخێر',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.amber,
                                ),
                                child: Text('بەڵێ، هێنانەوە'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (confirm) {
                      bool success = await provider.restoreDatabase();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'داتاکان بە سەرکەوتوویی گەڕێنرانەوە'
                                  : 'هەڵەیەک ڕوویدا یان فایلەکە گونجاو نەبوو',
                            ),
                            backgroundColor: success
                                ? AppColors.emerald
                                : AppColors.rose,
                          ),
                        );
                      }
                    }
                  },
                ),
                _SettingsCard(
                  width: isDesktop ? 400 : double.infinity,
                  icon: Icons.history_rounded,
                  color: AppColors.primary,
                  title: 'باکەپە خۆکارەکان (Auto Backups)',
                  description:
                      'ئەپەکە ڕۆژانە دوو جار خۆکارانە باکەپ هەڵدەگرێت. لێرەوە دەتوانیت یەکێک لە باکەپە خۆکارەکان بگەڕێنیتەوە. (ئەمە داتای ئێستا دەسڕێتەوە)',
                  buttonLabel: 'بینین و گەڕاندنەوە',
                  buttonIcon: Icons.restore_page_rounded,
                  buttonColor: AppColors.primary,
                  glowColor: AppColors.primary,
                  onPressed: () => _showAutoBackupsDialog(context, provider),
                ),
                _SettingsCard(
                  width: isDesktop ? 400 : double.infinity,
                  icon: Icons.table_view_rounded,
                  color: AppColors.emerald,
                  title: 'دەرکردنی داتا بۆ ئێکسڵ (Export)',
                  description:
                      'هەموو کاڵاکانی ناو کۆگاکەت بخە ناو فایلێکی ئێکسڵ بۆ ئەوەی ڕاپۆرتیان لێ دروست بکەیت یان کۆپییەکیان هەڵبگریت.',
                  buttonLabel: 'دەرکردنی ئێکسڵ',
                  buttonIcon: Icons.download_rounded,
                  buttonColor: AppColors.emerald,
                  glowColor: AppColors.emerald,
                  onPressed: () async {
                    final items = provider.items;
                    if (items.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('هیچ کاڵایەک نییە بۆ دەرکردن'),
                        ),
                      );
                      return;
                    }
                    bool success = await ExcelService.exportItemsToExcel(items);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'بە سەرکەوتوویی دەرکرا بۆ ئێکسڵ'
                                : 'هەڵەیەک ڕوویدا',
                          ),
                          backgroundColor: success
                              ? AppColors.emerald
                              : AppColors.rose,
                        ),
                      );
                    }
                  },
                ),
                _SettingsCard(
                  width: isDesktop ? 400 : double.infinity,
                  icon: Icons.post_add_rounded,
                  color: AppColors.violet,
                  title: 'هێنانەناوەوە لە ئێکسڵ (Import)',
                  description:
                      'بە یەکجار سەدان کاڵا زیاد بکە لە ڕێگەی فایلی ئێکسڵەوە. (فایلەکە پێویستە ستوونەکانی وەکو باکەپەکە بێت).',
                  buttonLabel: 'هێنانەناوەوە',
                  buttonIcon: Icons.upload_rounded,
                  buttonColor: AppColors.violet,
                  glowColor: AppColors.violet,
                  onPressed: () async {
                    final newItems = await ExcelService.importItemsFromExcel();
                    if (newItems != null && newItems.isNotEmpty) {
                      await provider.addItems(newItems);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '\${newItems.length} کاڵا بە سەرکەوتوویی زیادکرا',
                            ),
                            backgroundColor: AppColors.emerald,
                          ),
                        );
                      }
                    } else if (newItems != null && newItems.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('فایلەکە بەتاڵە یان کێشەی هەیە'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              'ڕووکار و دیزاین (Theme)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'گۆڕینی ڕەنگەکانی ئەپەکە (تاریک و ڕووناک)',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            _buildThemeSection(context, isDesktop),
            const SizedBox(height: 48),
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
    );
  }
  Widget _buildThemeSection(BuildContext context, bool isDesktop) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _SettingsCard(
              width: isDesktop ? 400 : double.infinity,
              icon: theme.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: theme.isDarkMode
                  ? AppColors.violet
                  : AppColors.amber,
              title: theme.isDarkMode ? 'دۆخی تاریک' : 'دۆخی ڕووناک',
              description:
                  'کرتە بکە بۆ گۆڕینی ڕەنگەکانی ئەپەکە لە نێوان تاریک و ڕووناک.',
              buttonLabel: theme.isDarkMode
                  ? 'گۆڕین بۆ ڕووناک'
                  : 'گۆڕین بۆ تاریک',
              buttonIcon: Icons.brightness_6_rounded,
              buttonColor: theme.isDarkMode
                  ? AppColors.violet
                  : AppColors.amber,
              glowColor: theme.isDarkMode ? AppColors.violet : AppColors.amber,
              onPressed: () {
                theme.toggleTheme();
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildSecuritySection(BuildContext context, bool isDesktop) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        bool hasCredentials = auth.username != null && auth.username!.isNotEmpty && auth.password != null && auth.password!.isNotEmpty;
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
                onPressed: () => _showCredentialsDialog(context, auth, isSetting: true),
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
                onPressed: () => _showCredentialsDialog(context, auth, isSetting: true),
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
                onPressed: () => _showCredentialsDialog(context, auth, isSetting: false),
              ),
            ],
          ],
        );
      },
    );
  }
  String _formatBackupDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} - ${two(dt.hour)}:${two(dt.minute)}';
  }

  void _showAutoBackupsDialog(
    BuildContext context,
    InventoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.history_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            const Expanded(child: Text('باکەپە خۆکارەکان')),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: FutureBuilder<List<BackupInfo>>(
            future: provider.getAutoBackups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final backups = snapshot.data ?? [];
              if (backups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'تا ئێستا هیچ باکەپێکی خۆکار نییە. لە کاتی بەکارهێنانی ئەپەکە خۆکارانە دروست دەبن.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: backups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = backups[i];
                  return ListTile(
                    leading: Icon(
                      Icons.backup_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(_formatBackupDate(b.modified)),
                    subtitle: Text(b.sizeLabel),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('گەڕاندنەوە'),
                      onPressed: () =>
                          _confirmAndRestore(ctx, context, provider, b),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('داخستن', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRestore(
    BuildContext dialogCtx,
    BuildContext screenCtx,
    InventoryProvider provider,
    BackupInfo backup,
  ) async {
    final confirm =
        await showDialog<bool>(
          context: dialogCtx,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.amber),
                const SizedBox(width: 10),
                const Text('دڵنیایت؟'),
              ],
            ),
            content: Text(
              'گەڕاندنەوەی باکەپی ${_formatBackupDate(backup.modified)} داتاکانی ئێستات دەسڕێتەوە.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('نەخێر', style: TextStyle(color: AppColors.muted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                ),
                child: const Text('بەڵێ، گەڕاندنەوە'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final success = await provider.restoreFromFile(backup.path);
    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
    if (screenCtx.mounted) {
      ScaffoldMessenger.of(screenCtx).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'داتاکان بە سەرکەوتوویی گەڕێنرانەوە'
                : 'هەڵەیەک ڕوویدا لە کاتی گەڕاندنەوە',
          ),
          backgroundColor: success ? AppColors.emerald : AppColors.rose,
        ),
      );
    }
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
          isSetting ? 'زانیاری هەژماری نوێ بنووسە' : 'دڵنیایت لە سڕینەوەی هەژمار؟',
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
                if (userController.text.isNotEmpty && passController.text.isNotEmpty) {
                  await auth.setCredentials(userController.text, passController.text);
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
