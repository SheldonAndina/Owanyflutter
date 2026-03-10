// Temporarily ignore deprecated 'withOpacity' warnings across this theme
// to allow incremental migration to the new color APIs.
// TODO: Replace `.withValues(alpha: )` usages with the new API or helper.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================
/// OWANY THEME - Premium Professional Design System
/// Modern, Luxe, Premium - Material 3 Ready
/// Version: 2.0 Professional Edition
/// ============================================================
class OwanyTheme {
  // 🎯 PALETA PRIMÁRIA PREMIUM
  static const Color primaryOrange = Color(0xFFFF7A3D);
  static const Color primaryOrangeDark = Color(0xFFE65100);
  static const Color primaryOrangeLight = Color(0xFFFFB380);
  static const Color primaryBrown = Color(0xFF1F1714);
  static const Color textDark = Color(0xFF0D0D0D);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSecondary = Color(0xFF6B5E54);

  // 🤍 SUPERFÍCIES E FUNDOS PREMIUM
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFBFAF8);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceHover = Color(0xFFF0F0F0);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);

  // 🌙 DARK MODE PREMIUM
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1F1F1F);
  static const Color darkSurfaceElevated = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkMuted = Color(0xFFB0B0B0);
  static const Color darkBorder = Color(0xFF404040);

  // 🌈 STATUS COLORS REFINED
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // 🎨 ACCENT COLORS PREMIUM
  static const Color accent = Color(0xFFFF9F5A);
  static const Color accentLight = Color(0xFFFFE5D0);
  static const Color accentDark = Color(0xFFCC6A2A);
  static const Color softOrange = Color(0xFFFFF0E6);

  // 🔵 ADDITIONAL COLORS
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightSlate = Color(0xFF94A3B8);
  static const Color darkSlate = Color(0xFF475569);
  
  // 🟣 PURPLE FOR EXTRAVIADO STATE
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFEDE9FE);
  
  // ⚫ GRAY FOR INUTILIZADO STATE
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFFF3F4F6);

  // 🎯 ALIASES FOR LEGACY REFERENCES
  static const Color successGreen = success;
  static const Color errorRed = error;
  static const Color warningOrange = warning;
  static const Color primary = primaryBrown;

  /* ============================================================
   * 🌙 DYNAMIC THEME HELPERS
   * Use these methods to get colors that automatically adapt to dark/light mode
   * ============================================================ */

  /// Returns true if current theme is dark mode
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  /// Background color (adapts to theme)
  static Color backgroundColor(BuildContext context) => isDark(context) ? darkBackground : background;

  /// Card/Surface color (adapts to theme)
  static Color cardColor(BuildContext context) => isDark(context) ? darkSurfaceElevated : white;

  /// Surface color (adapts to theme)
  static Color surfaceColor(BuildContext context) => isDark(context) ? darkSurface : surface;

  /// Primary text color (adapts to theme)
  static Color textPrimary(BuildContext context) => isDark(context) ? darkText : primaryBrown;

  /// Secondary/muted text color (adapts to theme)
  static Color textMutedColor(BuildContext context) => isDark(context) ? darkMuted : textSecondary;

  /// Border color (adapts to theme)
  static Color borderColor(BuildContext context) => isDark(context) ? darkBorder : borderLight;

  /// Card decoration with proper colors for current theme
  static BoxDecoration cardDecoration(BuildContext context, {double radius = 12}) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark ? darkSurfaceElevated : white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: dark ? darkBorder : borderLight.withValues(alpha: 0.3)),
      boxShadow: dark
          ? []
          : [BoxShadow(color: primaryBrown.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    );
  }

  /// Elevated card decoration (slightly lighter in dark mode)
  static BoxDecoration elevatedCardDecoration(BuildContext context, {double radius = 16}) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark ? darkSurfaceElevated : white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: dark ? darkBorder : borderLight),
      boxShadow: dark
          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
          : [BoxShadow(color: primaryOrange.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
    );
  }

  // ============================================================
  // 📐 RESPONSIVE BREAKPOINTS & HELPERS
  // ============================================================

  /// Breakpoints para layouts responsivos
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  /// Max-width para formulários (auth, change password, etc.)
  static const double maxWidthFormSmall = 480.0;
  /// Max-width para formulários complexos (create user, apartments, etc.)
  static const double maxWidthForm = 600.0;
  /// Max-width para listas e detalhes
  static const double maxWidthContent = 800.0;
  /// Max-width para telas amplas (relatórios, dashboards)
  static const double maxWidthWide = 1100.0;

  /// Verifica se é mobile (< 600dp)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointMobile;

  /// Verifica se é tablet (600-900dp)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointMobile &&
      MediaQuery.of(context).size.width < breakpointTablet;

  /// Verifica se é desktop (>= 900dp)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointTablet;

  /// Retorna padding horizontal responsivo
  static double responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) return 16.0;
    if (width < breakpointTablet) return 24.0;
    return 32.0;
  }

  /// Widget wrapper que centraliza e limita a largura do conteúdo.
  /// Use em todas as telas para garantir boa visualização no desktop/web.
  static Widget responsiveBody({
    required Widget child,
    double maxWidth = maxWidthForm,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Input decoration that adapts to theme
  static InputDecoration adaptiveInputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    final dark = isDark(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: dark ? darkMuted : textSecondary) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: dark ? darkSurface : surface,
      labelStyle: TextStyle(color: dark ? darkMuted : textSecondary),
      hintStyle: TextStyle(color: dark ? darkMuted.withValues(alpha: 0.7) : textSecondary.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? darkBorder : borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? darkBorder : borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Text style for titles that adapts to theme
  static TextStyle titleStyle(BuildContext context, {double fontSize = 18}) =>
      TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: textPrimary(context));

  /// Text style for body text that adapts to theme
  static TextStyle bodyStyle(BuildContext context, {double fontSize = 14}) =>
      TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400, color: textPrimary(context));

  /// Text style for muted/secondary text that adapts to theme
  static TextStyle mutedStyle(BuildContext context, {double fontSize = 12}) =>
      TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: textMutedColor(context));

  /// Adaptive overlay color - white in light mode, dark in dark mode
  /// Useful for semi-transparent overlays, borders, etc.
  static Color adaptiveOverlay(BuildContext context, {double opacity = 0.2}) {
    final dark = isDark(context);
    return (dark ? Colors.black : Colors.white).withValues(alpha: opacity);
  }

  /// Adaptive text color for overlaid text - white in light mode, dark text in dark mode
  static Color adaptiveTextOverlay(BuildContext context) {
    return isDark(context) ? textPrimary(context) : Colors.white;
  }

  /* ============================================================
   * TYPOGRAPHY SYSTEM
   * ============================================================ */

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textDark,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textDark,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: textDark,
    height: 1.3,
  );

  // Heading Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: textDark,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textDark,
    height: 1.4,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: textDark,
    height: 1.4,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textDark, height: 1.5);

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textDark,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.5,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: textDark,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: textMuted,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: textMuted,
    height: 1.4,
  );

  // Legacy styles (mantidos para compatibilidade)
  static const TextStyle headerStyle = displayMedium;
  static const TextStyle bodyStyleLegacy = bodyMedium;

  /* ============================================================
   * INPUT DECORATIONS
   * ============================================================ */

  static InputDecoration inputDecoration({
    BuildContext? context,
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
    String? helperText,
    String? errorText,
    bool? dark,
  }) {
    final useDark =
        dark ?? (context != null && Theme.of(context).brightness == Brightness.dark);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      errorText: errorText,
      labelStyle: TextStyle(color: useDark ? darkMuted : textMuted, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(
        color: useDark ? darkMuted.withValues(alpha: 0.5) : textMuted.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      prefixIcon: icon != null ? Icon(icon, color: primaryOrange, size: 20) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: useDark ? darkSurface : surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: useDark ? darkBorder : borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: useDark ? darkBorder.withValues(alpha: 0.5) : borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  /* ============================================================
   * BUTTON STYLES - PREMIUM EDITION
   * ============================================================ */

  // Primary Button (Filled with Premium Shadow)
  static ButtonStyle primaryButtonStyle({bool dark = false, bool isLoading = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryOrange,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: primaryOrange.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15)),
      surfaceTintColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
    );
  }

  // Secondary Button (Outlined - Premium)
  static ButtonStyle secondaryButtonStyle({bool dark = false}) {
    return OutlinedButton.styleFrom(
      foregroundColor: dark ? darkText : textDark,
      side: BorderSide(color: dark ? darkBorder : borderMedium, width: 2),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.3),
    ).copyWith(overlayColor: WidgetStateProperty.all((dark ? darkText : textDark).withValues(alpha: 0.08)));
  }

  // Tertiary Button (Ghost/Text - Premium)
  static ButtonStyle tertiaryButtonStyle({bool dark = false}) {
    return TextButton.styleFrom(
      foregroundColor: dark ? darkMuted : textMuted,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
    ).copyWith(overlayColor: WidgetStateProperty.all((dark ? darkMuted : textMuted).withValues(alpha: 0.08)));
  }

  // Success Button
  static ButtonStyle successButtonStyle({bool outlined = false}) {
    if (outlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: success,
        side: const BorderSide(color: success, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      );
    }

    return ElevatedButton.styleFrom(
      backgroundColor: success,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: success.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
  }

  // Destructive Button (Premium)
  static ButtonStyle destructiveButtonStyle({bool outlined = false}) {
    if (outlined) {
      return OutlinedButton.styleFrom(
        foregroundColor: error,
        side: const BorderSide(color: error, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      );
    }

    return ElevatedButton.styleFrom(
      backgroundColor: error,
      foregroundColor: Colors.white,
      elevation: 8,
      shadowColor: error.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    );
  }

  /* ============================================================
   * CARD DECORATIONS - PREMIUM EDITION
   * ============================================================ */

  // Premium Elevated Card (com sombra luxuosa)
  static BoxDecoration premiumCardDecoration({bool dark = false}) {
    return BoxDecoration(
      color: dark ? darkSurfaceElevated : white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.1 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Glass Morphism Card (Premium effect)
  static BoxDecoration glassCardDecoration({bool dark = false}) {
    return BoxDecoration(
      color: (dark ? darkSurface : white).withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.1), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Gradient Card (Premium)
  static BoxDecoration gradientCardDecoration({bool dark = false, bool useOrange = true}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: useOrange
            ? [primaryOrange.withValues(alpha: 0.95), primaryOrangeDark.withValues(alpha: 0.9)]
            : dark
            ? [darkSurfaceElevated, darkSurface]
            : [accentLight, surface],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Subtle Card (minimal)
  static BoxDecoration subtleCardDecoration({bool dark = false}) {
    return BoxDecoration(
      color: dark ? darkSurface : surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: dark ? darkBorder : borderLight, width: 1),
    );
  }

  // Flat Card (sem sombra - para listas)
  static BoxDecoration flatCardDecoration({bool dark = false}) {
    return BoxDecoration(color: dark ? darkSurface : surface, borderRadius: BorderRadius.circular(16));
  }

  // Outlined Card
  static BoxDecoration outlinedCardDecoration({bool dark = false}) {
    return BoxDecoration(
      color: dark ? darkSurface : white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: dark ? darkBorder : borderLight, width: 1),
    );
  }

  // Elevated Card (com sombra suave) - Legacy version
  static BoxDecoration elevatedCardDecorationLegacy({bool dark = false}) {
    return BoxDecoration(
      color: dark ? darkSurface : white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /* ============================================================
   * SNACKBAR - PREMIUM EDITION
   * ============================================================ */

  static SnackBar snackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = success;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = error;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = warning;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = info;
        icon = Icons.info_rounded;
        break;
    }

    return SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.2),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      duration: duration,
      action: action,
    );
  }

  /* ============================================================
   * CHIPS
   * ============================================================ */

  static BoxDecoration chipDecoration({required Color color, bool outlined = false, bool dark = false}) {
    if (outlined) {
      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      );
    }

    return BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20));
  }

  /* ============================================================
   * DIVIDERS
   * ============================================================ */

  static Divider divider({bool dark = false, double indent = 0}) {
    return Divider(color: dark ? darkBorder : borderLight, thickness: 1, height: 1, indent: indent, endIndent: indent);
  }

  static VerticalDivider verticalDivider({bool dark = false}) {
    return VerticalDivider(color: dark ? darkBorder : borderLight, thickness: 1, width: 1);
  }

  /* ============================================================
   * THEME DATA - Material 3 PREMIUM
   * ============================================================ */

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primaryOrange,
    fontFamily: 'Inter',

    // Color Scheme - Premium
    colorScheme: const ColorScheme.light(
      primary: primaryOrange,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      tertiary: primaryBlue,
      error: error,
      onError: Colors.white,
      surface: white,
      onSurface: textDark,
      outline: borderMedium,
      surfaceDim: surface,
      surfaceBright: white,
    ),

    // AppBar Theme - Premium
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: white,
      foregroundColor: textDark,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      iconTheme: IconThemeData(color: textDark, size: 26),
      centerTitle: false,
    ),

    // Card Theme - Premium
    cardTheme: CardThemeData(
      elevation: 8,
      color: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withValues(alpha: 0.08),
    ),

    // Text Theme - Premium
    textTheme: const TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),

    // Input Theme - Premium
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: textMuted),
      hintStyle: TextStyle(fontSize: 14, color: textMuted.withValues(alpha: 0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderMedium, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryOrange, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: error, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
    ),

    // Button Themes - Premium
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle()),

    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle()),

    textButtonTheme: TextButtonThemeData(style: tertiaryButtonStyle()),

    // FAB Theme - Premium
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryOrange,
      foregroundColor: Colors.white,
      elevation: 12,
      hoverElevation: 14,
      focusElevation: 12,
      highlightElevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    // Bottom Nav Theme - Premium
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      elevation: 12,
      backgroundColor: white,
      selectedItemColor: primaryOrange,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),

    // Divider Theme - Premium
    dividerTheme: const DividerThemeData(color: borderLight, thickness: 1, space: 1),

    // Dialog Theme - Premium
    dialogTheme: DialogThemeData(
      elevation: 16,
      backgroundColor: white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: headlineLarge.copyWith(fontWeight: FontWeight.w800),
      contentTextStyle: bodyMedium,
    ),

    // Chip Theme - Premium
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      deleteIconColor: textMuted,
      disabledColor: surface.withValues(alpha: 0.5),
      selectedColor: primaryOrange.withValues(alpha: 0.15),
      secondarySelectedColor: softOrange,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      labelStyle: labelMedium.copyWith(fontWeight: FontWeight.w700),
      secondaryLabelStyle: labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderLight),
      ),
      side: const BorderSide(color: borderLight),
    ),

    // Slider Theme - Premium
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryOrange,
      inactiveTrackColor: borderLight,
      thumbColor: primaryOrange,
      overlayColor: primaryOrange.withValues(alpha: 0.2),
      valueIndicatorColor: primaryOrange,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primaryOrange,
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.dark(
      primary: primaryOrange,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      tertiary: primaryBlue,
      error: error,
      onError: Colors.white,
      surface: darkSurface,
      onSurface: darkText,
      outline: darkBorder,
      surfaceDim: darkSurface,
      surfaceBright: darkSurfaceElevated,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(color: darkText, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      elevation: 8,
      color: darkSurfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black.withValues(alpha: 0.3),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: darkText,
        height: 1.2,
      ),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkText, height: 1.5),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      labelStyle: const TextStyle(color: darkMuted, fontSize: 14),
      hintStyle: TextStyle(color: darkMuted.withValues(alpha: 0.7), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.6), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryOrange, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle(dark: true)),

    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle(dark: true)),

    textButtonTheme: TextButtonThemeData(style: tertiaryButtonStyle(dark: true)),

    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryOrange,
      foregroundColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    // Dialog Theme for Dark Mode
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: darkText,
      ),
    ),
  );
}

/* ============================================================
 * ENUMS
 * ============================================================ */

enum SnackBarType { success, error, warning, info }

/* ============================================================
 * EXTENSIONS
 * ============================================================ */

extension ColorExtension on Color {
  /// Retorna uma cor mais clara
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Retorna uma cor mais escura
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
