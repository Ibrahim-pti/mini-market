import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, FlutterError, FlutterErrorDetails;
import 'package:provider/provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Workaround بۆ بەگی Flutter لەسەر دیسکتۆپ کاتێک لایەی نووسینی نا-لاتین
  // (کوردی/فارسی/عەرەبی) بەکاردەهێنرێت: هەندێک KeyDownEvent دووجار دێن و
  // assertion ـی "physical key is already pressed" هەڵدەستێنن. ئەمە لە
  // debug mode دا تەنها نۆیزی لۆگە و کاریگەری لەسەر ئەرکی ئەپە نییە، بۆیە
  // تەنها ئەو هەڵە تایبەتە بێدەنگ دەکەین و هەڵەکانی تر وەک خۆیان دەمێننەوە.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception;
    if (exception is AssertionError &&
        exception.message.toString().contains('is already pressed')) {
      return; // بەگی ناسراوی کیبۆردی دیسکتۆپی Flutter — پشتگوێ دەخرێت
    }
    originalOnError?.call(details);
  };

  runApp(const MiniMarketApp());
}

class MiniMarketApp extends StatelessWidget {
  const MiniMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.desktop_mac_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ئەم بەرنامەیە تەنها بۆ ماک و ویندۆز دروستکراوە',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تکایە بەرنامەکە لەسەر (macOS) کارپێبکە.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          return MaterialApp(
            // Rebuild the whole tree when the theme flips so every screen
            // (including pushed routes) re-reads the updated AppColors.
            key: ValueKey(theme.isDarkMode),
            title: 'مارکێت گوڵینا',
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.light(),
            darkTheme: AppTheme.light(), // Re-evaluates AppColors which is updated by ThemeProvider
            home: !auth.isInitialized 
              ? Scaffold(backgroundColor: AppColors.background, body: const Center(child: CircularProgressIndicator()))
              : (auth.isAuthenticated ? const HomeScreen() : const LockScreen()),
          );
        }
      ),
    );
  }
}
