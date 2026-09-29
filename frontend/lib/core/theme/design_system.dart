import 'package:flutter/material.dart';

class FTColors {
  static const Color primary = Color(0xFF168A55);
  static const Color primaryDark = Color(0xFF106B43);
  static const Color primaryLight = Color(0xFFEAF7F0);
  
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFFF4DB);
  
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF17211B);
  static const Color textSecondary = Color(0xFF667085);
  static const Color border = Color(0xFFE4E7EC);
  
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}

class FTTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: FTColors.textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: FTColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: FTColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: FTColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: FTColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: FTColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: FTColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: FTColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: FTColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FTColors.surface,
  );
}

class FTSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 48.0;
}

class FTRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 20.0;
}

class FTShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];
}

class FTTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: FTTypography.fontFamily,
      scaffoldBackgroundColor: FTColors.background,
      colorScheme: const ColorScheme.light(
        primary: FTColors.primary,
        secondary: FTColors.secondary,
        surface: FTColors.surface,
        error: FTColors.error,
        onPrimary: FTColors.surface,
        onSecondary: FTColors.surface,
        onSurface: FTColors.textPrimary,
        onError: FTColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FTColors.surface,
        foregroundColor: FTColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: FTColors.textPrimary),
        titleTextStyle: FTTypography.heading3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FTColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FTSpacing.md,
          vertical: FTSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FTRadius.medium),
          borderSide: const BorderSide(color: FTColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FTRadius.medium),
          borderSide: const BorderSide(color: FTColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FTRadius.medium),
          borderSide: const BorderSide(color: FTColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FTRadius.medium),
          borderSide: const BorderSide(color: FTColors.error),
        ),
        labelStyle: FTTypography.label,
        hintStyle: FTTypography.bodySmall,
        errorStyle: FTTypography.caption.copyWith(color: FTColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FTColors.primary,
          foregroundColor: FTColors.surface,
          textStyle: FTTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: FTSpacing.xl,
            vertical: FTSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FTRadius.medium),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FTColors.primary,
          side: const BorderSide(color: FTColors.primary),
          textStyle: FTTypography.button.copyWith(color: FTColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: FTSpacing.xl,
            vertical: FTSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FTRadius.medium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FTColors.primary,
          textStyle: FTTypography.button.copyWith(color: FTColors.primary),
        ),
      ),
      cardTheme: CardThemeData(
        color: FTColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FTRadius.large),
          side: const BorderSide(color: FTColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
