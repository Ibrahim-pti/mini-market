import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mini_market/providers/theme_provider.dart';
import 'package:mini_market/providers/auth_provider.dart';
import 'package:mini_market/providers/inventory_provider.dart';
import 'package:mini_market/theme/app_theme.dart';
import 'package:mini_market/services/backup_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'calculator_screen.dart';

/// One launchable section of the app.
class _Section {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function() build;
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.build,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final List<_Section> _sections = [
    _Section(
      title: 'بەشی فرۆشتن',
      icon: Icons.point_of_sale_rounded,
      color: const Color(0xFF2E8B57), // Sea Green
      build: () => const PosScreen(),
    ),
    _Section(
      title: 'بەرهەم',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFF008080), // Teal
      build: () => const InventoryScreen(),
    ),
    _Section(
      title: 'ڕاپۆرتەکان',
      icon: Icons.assignment_outlined,
      color: const Color(0xFF6A5ACD), // Slate Blue
      build: () => const ReportsScreen(),
    ),
    _Section(
      title: 'ڕێکخستنەکان',
      icon: Icons.settings_outlined,
      color: const Color(0xFF008B8B), // Dark Cyan
      build: () => const SettingsScreen(),
    ),
    _Section(
      title: 'حاسیبە',
      icon: Icons.calculate_outlined,
      color: const Color(0xFF483D8B), // Dark Slate Blue
      build: () => const CalculatorScreen(),
    ),
  ];

  void _open(_Section section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _SectionPage(title: section.title, child: section.build()),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('داخستنی سیستەم'),
        content: const Text('دڵنیایت لە داخستنی سیستەمەکە؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('نەخێر', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('بەڵێ، داخستن'),
          ),
        ],
      ),
    );
    if (ok == true) exit(0);
  }

  String _fmtBackupDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}/${two(dt.month)}/${two(dt.day)} - ${two(dt.hour)}:${two(dt.minute)}';
  }

  /// Opens the backup/restore menu from the home launcher tile.
  Future<void> _showBackupMenu() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            const Expanded(child: Text('باکەپ و گەڕاندنەوە')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.backup_rounded, color: AppColors.sky),
              title: const Text('وەرگرتنی باکەپ'),
              subtitle: const Text('کۆپییەک هەڵبگرە لە فۆڵدەرێک (وەک USB)'),
              onTap: () {
                Navigator.pop(ctx);
                _backupNow();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.history_rounded, color: AppColors.primary),
              title: const Text('گەڕاندنەوە لە باکەپە خۆکارەکان'),
              subtitle: const Text('یەکێک لە باکەپە ڕۆژانەکان بگەڕێنەوە'),
              onTap: () {
                Navigator.pop(ctx);
                _showAutoBackupsDialog();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.file_open_rounded, color: AppColors.amber),
              title: const Text('هێنانەوەی فایلی باکەپ'),
              subtitle: const Text('فایلێکی باکەپ هەڵبژێرە لە کۆمپیوتەرەکەت'),
              onTap: () {
                Navigator.pop(ctx);
                _restoreFromFile();
              },
            ),
          ],
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

  Future<void> _backupNow() async {
    final provider = context.read<InventoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.backupDatabase();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'باکەپ بە سەرکەوتوویی گیرا'
              : 'هەڵەیەک ڕوویدا لە کاتی باکەپگرتن',
        ),
        backgroundColor: success ? AppColors.emerald : AppColors.rose,
      ),
    );
  }

  /// Asks for confirmation, then restores from a user-picked backup file.
  Future<void> _restoreFromFile() async {
    final confirm = await _confirmRestore('هێنانەوەی فایلی باکەپ');
    if (confirm != true) return;
    if (!mounted) return;

    final provider = context.read<InventoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.restoreDatabase();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'داتاکان بە سەرکەوتوویی گەڕێنرانەوە'
              : 'هەڵەیەک ڕوویدا یان فایلەکە گونجاو نەبوو',
        ),
        backgroundColor: success ? AppColors.emerald : AppColors.rose,
      ),
    );
  }

  Future<bool?> _confirmRestore(String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.amber),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: const Text(
          'گەڕاندنەوەی باکەپ داتاکانی ئێستات دەسڕێتەوە و جێگەی دەگرێتەوە. دڵنیایت؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('نەخێر', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
            child: const Text('بەڵێ، گەڕاندنەوە'),
          ),
        ],
      ),
    );
  }

  /// Lists the automatic backups and lets the user restore one.
  Future<void> _showAutoBackupsDialog() async {
    final provider = context.read<InventoryProvider>();
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
                    title: Text(_fmtBackupDate(b.modified)),
                    subtitle: Text(b.sizeLabel),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('گەڕاندنەوە'),
                      onPressed: () => _restoreAutoBackup(dialogCtx, b),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('داخستن', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreAutoBackup(
    BuildContext dialogCtx,
    BackupInfo backup,
  ) async {
    final confirm = await _confirmRestore(
      'گەڕاندنەوەی باکەپی ${_fmtBackupDate(backup.modified)}',
    );
    if (confirm != true) return;
    if (!mounted) return;

    final provider = context.read<InventoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await provider.restoreFromFile(backup.path);
    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
    if (!mounted) return;
    messenger.showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(color: AppColors.background),
          // Purple Orb (Top Right)
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF8B5CF6,
                ).withOpacity(theme.isDarkMode ? 0.2 : 0.12),
              ),
            ),
          ),
          // Cyan Orb (Bottom Left)
          Positioned(
            bottom: -100,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF06B6D4,
                ).withOpacity(theme.isDarkMode ? 0.15 : 0.08),
              ),
            ),
          ),
          // Pink Orb (Center Left)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFEC4899,
                ).withOpacity(theme.isDarkMode ? 0.12 : 0.06),
              ),
            ),
          ),
          // Heavy Blur Layer for Glassmorphism
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Subtle Dotted Pattern Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(
                color: theme.isDarkMode
                    ? Colors.white.withOpacity(0.04)
                    : AppColors.ink.withOpacity(0.03),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        int cols = c.maxWidth > 1200
                            ? 5
                            : (c.maxWidth > 900
                                ? 4
                                : (c.maxWidth > 650
                                    ? 3
                                    : (c.maxWidth > 400 ? 2 : 1)));
                        final tiles = <Widget>[
                          ..._sections.map(
                            (s) => _LauncherTile(
                              title: s.title,
                              icon: s.icon,
                              color: s.color,
                              onTap: () => _open(s),
                            ),
                          ),
                          _LauncherTile(
                            title:
                                'دۆلار: ${NumberFormat('#,##0').format(context.watch<InventoryProvider>().dollarRate.toInt())}',
                            icon: Icons.currency_exchange_rounded,
                            color: const Color(0xFFB8860B),
                            onTap: () async {
                              final provider =
                                  context.read<InventoryProvider>();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('لە نوێبوونەوەدایە...')),
                              );
                              await provider.fetchDollarRateFromApi();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'نوێکرایەوە: ${NumberFormat('#,##0').format(provider.dollarRate.toInt())}'),
                                    backgroundColor: AppColors.emerald,
                                  ),
                                );
                              }
                            },
                          ),
                          _LauncherTile(
                            title: 'باکەپی داتا',
                            icon: Icons.cloud_upload_outlined,
                            color: const Color(0xFF1E90FF), // Dodger Blue
                            onTap: _showBackupMenu,
                          ),
                          _LauncherTile(
                            title: 'داخستن',
                            icon: Icons.power_settings_new_rounded,
                            color: const Color(0xFFB22222), // Firebrick
                            filled: true,
                            onTap: _confirmExit,
                          ),
                        ];
                        return GridView.count(
                          crossAxisCount: cols,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.7, // Taller boxes
                          children: tiles,
                        );
                      },
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.developer_mode_rounded,
                            size: 16, color: AppColors.muted),
                        const SizedBox(width: 8),
                        Text(
                          'دروستکراوە لە لایەن ',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'ibrahim tech',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '  |  ٠٧٥١٢٥٩٦٠٥٠',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDarkMode;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Colors.white.withOpacity(isDark ? 0.05 : 0.6)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          // 1. Date / time (Right)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const _LiveClock(),
                ],
              ),
            ),
          ),
          // 2. Title (Center)
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.storefront_rounded,
                        color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'مارکێت گوڵینا',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 3. Controls (Left)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.05 : 0.8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconButton(
                      icon: isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      onTap: () => context.read<ThemeProvider>().toggleTheme(),
                    ),
                    const SizedBox(width: 4),
                    Container(width: 1.5, height: 24, color: AppColors.border),
                    const SizedBox(width: 4),
                    _iconButton(
                      icon: Icons.lock_outline_rounded,
                      onTap: () => context.read<AuthProvider>().lock(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 24, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

/// A white box with a centered colored icon and a label below.
class _LauncherTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _LauncherTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_LauncherTile> createState() => _LauncherTileState();
}

class _LauncherTileState extends State<_LauncherTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform:
            _hover ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color, // Solid color
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withOpacity(0.15),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen wrapper for a section, with a back button to the launcher.
class _SectionPage extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: Border(bottom: BorderSide(color: AppColors.border)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              tooltip: 'گەڕانەوە',
              onPressed: () {
                // Drop focus from any active text field first so a single press
                // always pops the page (otherwise the first click can be spent
                // just unfocusing the field).
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              title,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
          ),
          body: child,
        ));
  }
}

/// Live date/time display. Keeps its own per-second timer so only this small
/// widget rebuilds every tick — the expensive blurred background of the home
/// screen no longer repaints once a second.
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          DateFormat('yyyy/MM/dd').format(_now),
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '${DateFormat('hh:mm:ss').format(_now)} ${_now.hour >= 12 ? "ئێوارە" : "بەیانی"}',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      color != oldDelegate.color;
}
