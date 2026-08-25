import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Dark backgrounds
  static const Color background = Color(0xFF0F1419);
  static const Color surface = Color(0xFF1A1F26);
  static const Color surfaceVariant = Color(0xFF232930);
  static const Color surfaceElevated = Color(0xFF2A3038);

  // Light backgrounds
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE9EDF3);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  // Accents
  static const Color primary = Color(0xFF5B8DEF);
  static const Color primaryVariant = Color(0xFF7BA3F2);
  static const Color secondary = Color(0xFF9B7BFF);

  // Dark text
  static const Color onBackground = Color(0xFFE8ECF1);
  static const Color onSurface = Color(0xFFC5CAD3);
  static const Color onSurfaceVariant = Color(0xFF8A919C);

  // Light text
  static const Color lightOnBackground = Color(0xFF18212B);
  static const Color lightOnSurface = Color(0xFF33404D);
  static const Color lightOnSurfaceVariant = Color(0xFF687582);

  // Functional
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color muted = Color(0xFF5A616B);

  // Liquid glass
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color lightGlassBackground = Color(0x66FFFFFF);
  static const Color lightGlassBorder = Color(0x33000000);
}

class AppRadii {
  static const double tag = 10; // 角标、小图标背景
  static const double button = 14; // 按钮、Space 内层标签
  static const double content = 18; // 头像、消息气泡
  static const double surface = 22; // 搜索框、输入框、卡片、Space 外层
  static const double nav = 28; // 底部导航
}

class AppTheme {
  static final ThemeData darkTheme = _buildTheme(
    Brightness.dark,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    surfaceElevated: AppColors.surfaceElevated,
    onBackground: AppColors.onBackground,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
  );

  static final ThemeData lightTheme = _buildTheme(
    Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    surfaceElevated: AppColors.lightSurfaceElevated,
    onBackground: AppColors.lightOnBackground,
    onSurface: AppColors.lightOnSurface,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
  );

  static ThemeData _buildTheme(
    Brightness brightness, {
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color surfaceElevated,
    required Color onBackground,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    final isLight = brightness == Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final colorScheme = isLight
        ? ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            surface: surface,
            onSurface: onSurface,
            onPrimary: Colors.white,
            surfaceContainerLow: const Color(0xFFF1F5F3),
            surfaceContainerHigh: surfaceElevated,
            surfaceContainerHighest: surfaceVariant,
            onSurfaceVariant: onSurfaceVariant,
            outline: const Color(0xFFB8C1CC),
            outlineVariant: const Color(0xFFD7DDE5),
          )
        : ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            surface: surface,
            onSurface: onSurface,
            onPrimary: Colors.white,
            surfaceContainerLow: surfaceElevated,
            surfaceContainerHigh: surfaceElevated,
            surfaceContainerHighest: surfaceVariant,
            onSurfaceVariant: onSurfaceVariant,
            outline: AppColors.muted,
            outlineVariant: const Color(0xFF343A42),
          );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onBackground,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
          statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: isLight
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.surface),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.surface),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.surface),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.surface),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: onSurfaceVariant, fontSize: 15),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.5,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        backgroundColor: surfaceElevated,
        contentTextStyle: TextStyle(
          color: onBackground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        elevation: 4,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}
