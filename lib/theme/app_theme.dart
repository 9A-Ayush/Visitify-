import 'package:flutter/material.dart';

class AppTheme {
  // Gate Ease App Color Palette - Blue Theme
  static const Color primary = Color(0xFF1976D2);        // Blue - Main brand color
  static const Color secondary = Color(0xFF1565C0);       // Dark Blue
  static const Color accent = Color(0xFF42A5F5);          // Light Blue
  static const Color background = Color(0xFFF5F7FA);      // Light Gray Background
  static const Color textPrimary = Color(0xFF212121);     // Dark Gray Text
  static const Color textSecondary = Color(0xFF757575);   // Medium Gray Text
  static const Color surface = Color(0xFFFFFFFF);         // White Surface
  static const Color success = Color(0xFF4CAF50);         // Green Success
  static const Color warning = Color(0xFFFF9800);         // Orange Warning
  static const Color error = Color(0xFFF44336);           // Red Error
  
  // Additional colors that complement blue theme
  static const Color purple = Color(0xFF9C27B0);          // Purple for visitors
  static const Color deepPurple = Color(0xFF673AB7);      // Deep Purple for analytics
  static const Color teal = Color(0xFF00BCD4);            // Cyan/Teal for vendors
  static const Color indigo = Color(0xFF3F51B5);          // Indigo for special features

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), background],
  );

  // Shadow Styles
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(10));

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary, width: 2),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: error),
      ),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
    );
  }

  // App Bar Theme
  static AppBarTheme appBarTheme = const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: textPrimary),
  );

  // Card Theme
  static CardThemeData cardTheme = CardThemeData(
    color: surface,
    elevation: 0,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: const RoundedRectangleBorder(borderRadius: cardRadius),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // Main Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: appBarTheme,
      cardTheme: cardTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
      fontFamily: 'Inter', // You can add custom fonts
    );
  }

  // Utility methods for consistent theming
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return primary;
      case 'resident':
        return accent;
      case 'guard':
        return indigo;
      case 'vendor':
        return teal;
      default:
        return textSecondary;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
        return success;
      case 'pending':
      case 'in_progress':
        return warning;
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return error;
      case 'suspended':
      case 'blocked':
        return textSecondary;
      default:
        return textSecondary;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return error;
      case 'high':
        return warning;
      case 'medium':
        return primary;
      case 'low':
        return success;
      default:
        return textSecondary;
    }
  }
}