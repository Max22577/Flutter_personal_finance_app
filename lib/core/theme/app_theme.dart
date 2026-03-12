import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors (Refined)
  static const Color lightPrimary = Color(0xFF6A11CB);
  static const Color lightSecondary = Color(0xFF2575FC);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFEADDFF); // For tonal buttons
  static const Color lightOnPrimaryContainer = Color(0xFF21005D);

  // Light surfaces (tonal hierarchy)
  static const Color lightBackground = Color(0xFFF5F6FA); 
  static const Color lightSurfaceContainerLow = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF1F3F9);
  static const Color lightSurfaceContainerHigh = Color(0xFFE9ECF5);

  static const Color lightOutline = Color(0xFF79747E);
  static const Color lightOutlineVariant = Color(0xFFCAC4D0); // For subtle glass borders
  static const Color lightShadow = Color(0xFF1A1C1E);
  
  // Dark theme colors (Refined)
  static const Color darkPrimary = Color(0xFFD0BCFF); // Softer purple for better readability
  static const Color darkSecondary = Color(0xFF03DAC6);
  static const Color darkOnPrimary = Color(0xFF381E72);

  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurfaceContainerLow = Color(0xFF17191F);
  static const Color darkSurface = Color(0xFF1E1F26);
  static const Color darkSurfaceContainer = Color(0xFF25272F);
  static const Color darkSurfaceContainerHigh = Color(0xFF2F313A);

  static const Color darkOutline = Color(0xFF938F99);
  static const Color darkOutlineVariant = Color(0xFF49454F); // For dark-mode glass borders
  static const Color darkShadow = Color(0xFF000000);
  
  // Common / Semantic colors
  static const Color incomeGreen = Color(0xFF4CAF50);
  static const Color expenseRed = Color(0xFFF44336);
}

class IllustrationTheme extends ThemeExtension<IllustrationTheme> {
  final Color? tintColor;
  final BlendMode? blendMode;

  const IllustrationTheme({
    required this.tintColor,
    required this.blendMode,
  });

  @override
  IllustrationTheme copyWith({Color? tintColor, BlendMode? blendMode}) {
    return IllustrationTheme(
      tintColor: tintColor ?? this.tintColor,
      blendMode: blendMode ?? this.blendMode,
    );
  }

  @override
  IllustrationTheme lerp(ThemeExtension<IllustrationTheme>? other, double t) {
    if (other is! IllustrationTheme) return this;
    return IllustrationTheme(
      tintColor: Color.lerp(tintColor, other.tintColor, t),
      blendMode: t < 0.5 ? blendMode : other.blendMode,
    );
  }
}

class FinancialColors extends ThemeExtension<FinancialColors> {
  final Color income;
  final Color expense;

  const FinancialColors({required this.income, required this.expense});

  @override
  FinancialColors copyWith({Color? income, Color? expense}) {
    return FinancialColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  FinancialColors lerp(ThemeExtension<FinancialColors>? other, double t) {
    if (other is! FinancialColors) return this;
    return FinancialColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
    );
  }
}

class AppThemes {
  // 1. Define the consistent Text Theme here
  static const TextTheme _baseTextTheme = TextTheme(
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    bodyLarge: TextStyle(fontSize: 16, letterSpacing: 0.5),
    bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0.25),
    bodySmall: TextStyle(fontSize: 12, letterSpacing: 0.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );

  // 2. Shared Component Styles (The Rhythm)
  static CardThemeData _cardTheme(bool isDark) => CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isDark ? AppColors.darkOutlineVariant : AppColors.lightOutlineVariant,
        width: 0.5,
      ),
    ),
    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
  );

  static InputDecorationTheme _inputTheme(bool isDark) => InputDecorationTheme(
    filled: true,
    fillColor: isDark ? AppColors.darkSurface : Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
    ),
  );

  // LIGHT THEME
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      onSurface: Colors.black87,
      onSurfaceVariant: Color(0xFF49454F), // Crucial for subtitles
      surfaceContainerLow: AppColors.lightSurfaceContainerLow, 
      surfaceContainer: AppColors.lightSurfaceContainer,
      surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      shadow: AppColors.lightShadow,
      error: Color(0xFFBA1A1A),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
    ),

    extensions: [
      const IllustrationTheme(
        tintColor: Color(0xFFF8F9FF), 
        blendMode: BlendMode.modulate,
      ),
      const FinancialColors(
        income: Color(0xFF4CAF50),
        expense: Color(0xFFF44336),
      ),
    ],
    textTheme: _baseTextTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87, fontFamily: 'Inter',),
    scaffoldBackgroundColor: AppColors.lightSurface,
    cardTheme: _cardTheme(false),
    inputDecorationTheme: _inputTheme(false),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent, // Better for your custom navbars
      foregroundColor: Colors.white, // Ensures icons/text are visible on transparent background
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: _baseTextTheme.titleLarge?.copyWith(color: Colors.white),
    ),
    elevatedButtonTheme: _buttonTheme(AppColors.lightPrimary, Colors.white),
  );

  // DARK THEME
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: Color(0xFF4F378B),
      onPrimaryContainer: Color(0xFFEADDFF),
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFCAC4D0),
      surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      shadow: AppColors.darkShadow,
      error: Color(0xFFFFB4AB),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
    ),
    extensions: [
      const IllustrationTheme( 
        tintColor: Color(0xFF121212), 
        blendMode: BlendMode.screen, 
      ),
      const FinancialColors(
        income: Color(0xFF81C784), // Lighter, desaturated green
        expense: Color(0xFFE57373), // Lighter, desaturated red
      ),
    ],
    textTheme: _baseTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white, fontFamily: 'Inter'),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardTheme: _cardTheme(true),
    inputDecorationTheme: _inputTheme(true),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: _baseTextTheme.titleLarge?.copyWith(color: Colors.white),
    ),
    elevatedButtonTheme: _buttonTheme(AppColors.darkPrimary, Colors.black),
  );

  static ElevatedButtonThemeData _buttonTheme(Color bg, Color fg) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      minimumSize: const Size.fromHeight(56), // Standardized height
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

class ThemeManager {
  // This is the map your Provider is looking for
  static Map<String, ThemeData> themes = {
    'Light': AppThemes.lightTheme,
    'Dark': AppThemes.darkTheme,
    // Add your other themes here
  };
}