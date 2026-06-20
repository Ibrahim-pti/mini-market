import 'package:flutter/material.dart';

/// ============================================================
///  Mini Market — Design System  ·  "Clean Minimal"
///  A single source of truth for colors, gradients, shadows,
///  radii, spacing and reusable text styles.
///  Light & Dark. Calm indigo accent. Airy whitespace.
/// ============================================================
class AppColors {
  AppColors._();

  static bool isDark = false;

  // Surfaces
  static Color background = const Color(0xFFF7F8FA); // app canvas
  static Color surface = const Color(0xFFFFFFFF); // cards
  static Color surfaceAlt = const Color(0xFFF2F4F7); // field fills / subtle
  static Color sidebar = const Color(0xFFFFFFFF);
  static Color header = const Color(0xFFFFFFFF);
  static Color bottomBar = const Color(0xFF0F172A);

  // Brand — calm indigo accent
  static Color primary = const Color(0xFF4F46E5);
  static Color primaryDark = const Color(0xFF4338CA);
  static Color primarySoft = const Color(0xFFEEF2FF);
  static Color violet = const Color(0xFF8B5CF6);
  static Color violetSoft = const Color(0xFFF5F3FF);

  // Accents
  static Color emerald = const Color(0xFF10B981);
  static Color emeraldSoft = const Color(0xFFECFDF5);
  static Color amber = const Color(0xFFF59E0B);
  static Color amberSoft = const Color(0xFFFFFBEB);
  static Color rose = const Color(0xFFEF4444);
  static Color roseSoft = const Color(0xFFFEF2F2);
  static Color sky = const Color(0xFF0EA5E9);
  static Color skySoft = const Color(0xFFF0F9FF);

  // Badges
  static Color badgePurple = const Color(0xFF8B5CF6);
  static Color badgeRed = const Color(0xFFEF4444);
  static Color badgeBlue = const Color(0xFF3B82F6);

  // Text
  static Color ink = const Color(0xFF0F172A); // slate-900
  static Color inkSoft = const Color(0xFF475569); // slate-600
  static Color muted = const Color(0xFF94A3B8); // slate-400

  // Lines
  static Color border = const Color(0xFFEAECF0);
  static Color borderStrong = const Color(0xFFD0D5DD);

  static void setDarkMode(bool isDark) {
    AppColors.isDark = isDark;
    if (isDark) {
      background = const Color(0xFF0B1120);
      surface = const Color(0xFF111827);
      surfaceAlt = const Color(0xFF1E293B);
      sidebar = const Color(0xFF0F172A);
      header = const Color(0xFF0F172A);
      bottomBar = const Color(0xFF0B1120);

      primary = const Color(0xFF818CF8);
      primaryDark = const Color(0xFF6366F1);
      primarySoft = const Color(0xFF1E1B4B);
      violet = const Color(0xFFA78BFA);
      violetSoft = const Color(0xFF2E1065);

      emerald = const Color(0xFF34D399);
      emeraldSoft = const Color(0xFF052E26);
      amber = const Color(0xFFFBBF24);
      amberSoft = const Color(0xFF3A2A06);
      rose = const Color(0xFFF87171);
      roseSoft = const Color(0xFF3B0D0D);
      sky = const Color(0xFF38BDF8);
      skySoft = const Color(0xFF082F49);

      badgePurple = const Color(0xFFA78BFA);
      badgeRed = const Color(0xFFF87171);
      badgeBlue = const Color(0xFF60A5FA);

      ink = const Color(0xFFF8FAFC);
      inkSoft = const Color(0xFFCBD5E1);
      muted = const Color(0xFF64748B);

      border = const Color(0xFF1E293B);
      borderStrong = const Color(0xFF334155);
    } else {
      background = const Color(0xFFF7F8FA);
      surface = const Color(0xFFFFFFFF);
      surfaceAlt = const Color(0xFFF2F4F7);
      sidebar = const Color(0xFFFFFFFF);
      header = const Color(0xFFFFFFFF);
      bottomBar = const Color(0xFF0F172A);

      primary = const Color(0xFF4F46E5);
      primaryDark = const Color(0xFF4338CA);
      primarySoft = const Color(0xFFEEF2FF);
      violet = const Color(0xFF8B5CF6);
      violetSoft = const Color(0xFFF5F3FF);

      emerald = const Color(0xFF10B981);
      emeraldSoft = const Color(0xFFECFDF5);
      amber = const Color(0xFFF59E0B);
      amberSoft = const Color(0xFFFFFBEB);
      rose = const Color(0xFFEF4444);
      roseSoft = const Color(0xFFFEF2F2);
      sky = const Color(0xFF0EA5E9);
      skySoft = const Color(0xFFF0F9FF);

      badgePurple = const Color(0xFF8B5CF6);
      badgeRed = const Color(0xFFEF4444);
      badgeBlue = const Color(0xFF3B82F6);

      ink = const Color(0xFF0F172A);
      inkSoft = const Color(0xFF475569);
      muted = const Color(0xFF94A3B8);

      border = const Color(0xFFEAECF0);
      borderStrong = const Color(0xFFD0D5DD);
    }
  }
}

class AppGradients {
  AppGradients._();

  static LinearGradient get brand => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.violet],
      );

  static const LinearGradient emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const LinearGradient violet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  );

  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
  );

  static const LinearGradient amber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const LinearGradient rose = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  );
}

class AppRadius {
  AppRadius._();
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppShadows {
  AppShadows._();

  /// Soft, barely-there elevation — the minimal look.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.isDark
              ? Colors.black.withOpacity(0.35)
              : const Color(0xFF101828).withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.isDark
              ? Colors.black.withOpacity(0.30)
              : const Color(0xFF101828).withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  /// Colored glow for primary actions.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Rabar',
      scaffoldBackgroundColor: AppColors.background,
      brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.violet,
        surface: AppColors.surface,
        error: AppColors.rose,
        brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return base.copyWith(
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Rabar',
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Rabar',
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Rabar',
          fontSize: 15,
          color: AppColors.inkSoft,
          height: 1.5,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.border),
        ),
        textStyle: TextStyle(fontFamily: 'Rabar', color: AppColors.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Rabar',
          color: AppColors.isDark ? AppColors.background : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.inkSoft),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.rose, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.rose, width: 1.6),
        ),
        labelStyle: TextStyle(
          color: AppColors.inkSoft,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        side: BorderSide(color: AppColors.border),
        labelStyle: TextStyle(
          fontFamily: 'Rabar',
          color: AppColors.inkSoft,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.surface),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.borderStrong),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  Reusable minimal UI building blocks.
/// ------------------------------------------------------------

/// A clean white card with hairline border and soft shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// A pill-shaped status / category badge.
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? bg;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple section title with optional trailing action.
class AppSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final IconData? icon;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
