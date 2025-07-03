// Design System for Flutter Application
// Green Theme - Veterinary Pharmacy Sales Assistant

import 'package:flutter/material.dart';

class AppDesignSystem {
  // Primary Green Colors
  static const Color primaryColor = Color(0xFF22C55E); // Green-500
  static const Color primaryForegroundColor = Color(0xFFFFFFFF);
  static const Color primaryDarkColor = Color(0xFF16A34A); // Green-600
  static const Color primaryLightColor = Color(0xFF4ADE80); // Green-400
  
  // Secondary Colors
  static const Color secondaryColor = Color(0xFFF0FDF4); // Green-50
  static const Color secondaryForegroundColor = Color(0xFF15803D); // Green-700
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color foregroundColor = Color(0xFF0C0C0D);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color cardForegroundColor = Color(0xFF0C0C0D);
  
  // Accent Colors with Green Tint
  static const Color accentColor = Color(0xFFDCFCE7); // Green-100
  static const Color accentForegroundColor = Color(0xFF166534); // Green-800
  static const Color mutedColor = Color(0xFFF1F5F9);
  static const Color mutedForegroundColor = Color(0xFF6B7280);
  
  // State Colors
  static const Color successColor = Color(0xFF22C55E); // Green-500
  static const Color successForegroundColor = Color(0xFFFFFFFF);
  static const Color warningColor = Color(0xFFF59E0B); // Amber-500
  static const Color warningForegroundColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444); // Red-500
  static const Color errorForegroundColor = Color(0xFFFFFFFF);
  static const Color infoColor = Color(0xFF3B82F6); // Blue-500
  static const Color infoForegroundColor = Color(0xFFFFFFFF);
  
  // Border & Input
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color inputColor = Color(0xFFE5E7EB);
  static const Color focusBorderColor = Color(0xFF22C55E); // Green-500
  
  // Popover
  static const Color popoverColor = Color(0xFFFFFFFF);
  static const Color popoverForegroundColor = Color(0xFF0C0C0D);

  // Green Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const String fontFamily = 'Roboto';

  // Font Sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
  static const double fontSize4xl = 36.0;

  // Font Weights
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Spacing
  static const double spacing0 = 0.0;
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  static const double spacing4 = 16.0;
  static const double spacing5 = 20.0;
  static const double spacing6 = 24.0;
  static const double spacing8 = 32.0;
  static const double spacing10 = 40.0;
  static const double spacing12 = 48.0;
  static const double spacing16 = 64.0;
  static const double spacing20 = 80.0;
  static const double spacing24 = 96.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusBase = 8.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radiusFull = 50.0;

  // Component Sizes
  static const double buttonHeightDefault = 44.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 52.0;
  static const double buttonHeightIcon = 44.0;

  static const double inputHeight = 44.0;
  static const double inputPadding = 16.0;

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  // Text Styles
  static TextStyle get textXs => const TextStyle(
    fontSize: fontSizeXs,
    fontWeight: fontWeightNormal,
    color: foregroundColor,
    fontFamily: fontFamily,
  );

  static TextStyle get textSm => const TextStyle(
    fontSize: fontSizeSm,
    fontWeight: fontWeightNormal,
    color: foregroundColor,
    fontFamily: fontFamily,
  );

  static TextStyle get textBase => const TextStyle(
    fontSize: fontSizeBase,
    fontWeight: fontWeightNormal,
    color: foregroundColor,
    fontFamily: fontFamily,
  );

  static TextStyle get textLg => const TextStyle(
    fontSize: fontSizeLg,
    fontWeight: fontWeightNormal,
    color: foregroundColor,
    fontFamily: fontFamily,
  );

  static TextStyle get headingLg => const TextStyle(
    fontSize: fontSize2xl,
    fontWeight: fontWeightBold,
    color: foregroundColor,
    fontFamily: fontFamily,
  );

  static TextStyle get headingXl => const TextStyle(
    fontSize: fontSize3xl,
    fontWeight: fontWeightBold,
    color: foregroundColor,
    fontFamily: fontFamily,
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: primaryForegroundColor,
    minimumSize: const Size(double.infinity, buttonHeightDefault),
    padding: const EdgeInsets.symmetric(horizontal: spacing6, vertical: spacing3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
    elevation: 2,
    shadowColor: primaryColor.withOpacity(0.3),
    textStyle: const TextStyle(
      fontSize: fontSizeBase,
      fontWeight: fontWeightSemibold,
      fontFamily: fontFamily,
    ),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: secondaryForegroundColor,
    minimumSize: const Size(double.infinity, buttonHeightDefault),
    padding: const EdgeInsets.symmetric(horizontal: spacing6, vertical: spacing3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      side: const BorderSide(color: primaryColor, width: 1),
    ),
    elevation: 0,
    textStyle: const TextStyle(
      fontSize: fontSizeBase,
      fontWeight: fontWeightSemibold,
      fontFamily: fontFamily,
    ),
  );

  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor, width: 1.5),
    minimumSize: const Size(double.infinity, buttonHeightDefault),
    padding: const EdgeInsets.symmetric(horizontal: spacing6, vertical: spacing3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
    textStyle: const TextStyle(
      fontSize: fontSizeBase,
      fontWeight: fontWeightSemibold,
      fontFamily: fontFamily,
    ),
  );

  static ButtonStyle get successButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: successForegroundColor,
    minimumSize: const Size(double.infinity, buttonHeightDefault),
    padding: const EdgeInsets.symmetric(horizontal: spacing6, vertical: spacing3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
    elevation: 2,
    shadowColor: successColor.withOpacity(0.3),
    textStyle: const TextStyle(
      fontSize: fontSizeBase,
      fontWeight: fontWeightSemibold,
      fontFamily: fontFamily,
    ),
  );

  static ButtonStyle get warningButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: warningColor,
    foregroundColor: warningForegroundColor,
    minimumSize: const Size(double.infinity, buttonHeightDefault),
    padding: const EdgeInsets.symmetric(horizontal: spacing6, vertical: spacing3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
    elevation: 2,
    shadowColor: warningColor.withOpacity(0.3),
    textStyle: const TextStyle(
      fontSize: fontSizeBase,
      fontWeight: fontWeightSemibold,
      fontFamily: fontFamily,
    ),
  );

  static ButtonStyle get errorButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: errorForegroundColor,
    minimumSize: const Size(double.infinity, buttonHeightDefault),
    padding: const EdgeInsets.symmetric(horizontal: spacing6, vertical: spacing3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    ),
    elevation: 2,
    shadowColor: errorColor.withOpacity(0.3),
    textStyle: const TextStyle(
      fontSize: fontSizeBase,
      fontWeight: fontWeightSemibold,
      fontFamily: fontFamily,
    ),
  );

  // Input Decoration
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: backgroundColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      borderSide: const BorderSide(color: borderColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      borderSide: const BorderSide(color: borderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      borderSide: const BorderSide(color: focusBorderColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      borderSide: const BorderSide(color: errorColor, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLg),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.all(inputPadding),
    hintStyle: const TextStyle(
      color: mutedForegroundColor,
      fontSize: fontSizeBase,
      fontFamily: fontFamily,
    ),
    labelStyle: const TextStyle(
      color: primaryColor,
      fontSize: fontSizeBase,
      fontWeight: fontWeightMedium,
      fontFamily: fontFamily,
    ),
  );

  // Card Style
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: borderColor.withOpacity(0.5)),
    boxShadow: shadowSm,
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: borderColor.withOpacity(0.3)),
    boxShadow: shadowMd,
  );

  // Theme Data
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: primaryForegroundColor,
      primaryContainer: accentColor,
      onPrimaryContainer: accentForegroundColor,
      secondary: secondaryColor,
      onSecondary: secondaryForegroundColor,
      surface: backgroundColor,
      onSurface: foregroundColor,
      surfaceContainerHighest: cardColor,
      onSurfaceVariant: cardForegroundColor,
      error: errorColor,
      onError: errorForegroundColor,
      outline: borderColor,
      outlineVariant: borderColor,
    ),
    fontFamily: fontFamily,
    textTheme: TextTheme(
      displayLarge: headingXl,
      displayMedium: headingLg,
      displaySmall: textLg.copyWith(fontWeight: fontWeightBold),
      headlineLarge: textLg.copyWith(fontWeight: fontWeightBold),
      headlineMedium: textBase.copyWith(fontWeight: fontWeightBold),
      headlineSmall: textSm.copyWith(fontWeight: fontWeightBold),
      titleLarge: textLg.copyWith(fontWeight: fontWeightSemibold),
      titleMedium: textBase.copyWith(fontWeight: fontWeightSemibold),
      titleSmall: textSm.copyWith(fontWeight: fontWeightSemibold),
      bodyLarge: textBase,
      bodyMedium: textSm,
      bodySmall: textXs,
      labelLarge: textBase.copyWith(fontWeight: fontWeightMedium),
      labelMedium: textSm.copyWith(fontWeight: fontWeightMedium),
      labelSmall: textXs.copyWith(fontWeight: fontWeightMedium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        borderSide: const BorderSide(color: focusBorderColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(inputPadding),
      hintStyle: const TextStyle(
        color: mutedForegroundColor,
        fontSize: fontSizeBase,
        fontFamily: fontFamily,
      ),
    ),
    // cardTheme: CardTheme(
    //   elevation: 2,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(radiusXl),
    //   ),
    //   margin: const EdgeInsets.all(spacing2),
    // ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: primaryForegroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: fontSize2xl,
        fontWeight: fontWeightBold,
        color: primaryForegroundColor,
        fontFamily: fontFamily,
      ),
    ),
  );

  // Predefined Component Widgets

  // Primary Button with Green Theme
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: shadowSm,
      ),
      child: ElevatedButton.icon(
        style: primaryButtonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryForegroundColor),
                ),
              )
            : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
        label: Text(text),
      ),
    );
  }

  // Success Button
  static Widget successButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      style: successButtonStyle,
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(successForegroundColor),
              ),
            )
          : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
      label: Text(text),
    );
  }

  // Text Input with Green Focus
  static Widget textInput({
    required String label,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textSm.copyWith(
            fontWeight: fontWeightSemibold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: spacing2),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: inputDecoration.copyWith(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  // Enhanced Card with Green Accent
  static Widget card({
    required Widget child,
    EdgeInsets? padding,
    bool elevated = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: elevated ? elevatedCardDecoration : cardDecoration,
        padding: padding ?? const EdgeInsets.all(spacing6),
        child: child,
      ),
    );
  }

  // Status Badge
  static Widget statusBadge({
    required String text,
    required String status, // 'success', 'warning', 'error', 'info'
  }) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'success':
        backgroundColor = successColor;
        textColor = successForegroundColor;
        break;
      case 'warning':
        backgroundColor = warningColor;
        textColor = warningForegroundColor;
        break;
      case 'error':
        backgroundColor = errorColor;
        textColor = errorForegroundColor;
        break;
      case 'info':
        backgroundColor = infoColor;
        textColor = infoForegroundColor;
        break;
      default:
        backgroundColor = primaryColor;
        textColor = primaryForegroundColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing3,
        vertical: spacing1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      child: Text(
        text,
        style: textXs.copyWith(
          color: textColor,
          fontWeight: fontWeightSemibold,
        ),
      ),
    );
}

  // Green Themed App Bar
  static PreferredSizeWidget appBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: primaryGradient,
        ),
      ),
    );
  }
}

// Usage Examples and Helper Methods

class VetPharmacyTheme {
  // Quick access to commonly used colors
  static const Color green = AppDesignSystem.primaryColor;
  static const Color lightGreen = AppDesignSystem.accentColor;
  static const Color darkGreen = AppDesignSystem.primaryDarkColor;
  
  // Quick text styles for pharmacy context
  static TextStyle get drugNameStyle => AppDesignSystem.textLg.copyWith(
    fontWeight: AppDesignSystem.fontWeightBold,
    color: AppDesignSystem.primaryColor,
  );

  static TextStyle get priceStyle => AppDesignSystem.textBase.copyWith(
    fontWeight: AppDesignSystem.fontWeightSemibold,
    color: AppDesignSystem.successColor,
  );

  static TextStyle get dosageStyle => AppDesignSystem.textSm.copyWith(
    color: AppDesignSystem.mutedForegroundColor,
    fontStyle: FontStyle.italic,
  );
}

