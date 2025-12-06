import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_typography.dart';
import '../constants/app_dimensions.dart';

/// Application theme configuration
/// Provides light and dark theme with consistent styling
class AppTheme {
  AppTheme._(); // Private constructor

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Gradient extensions
      extensions: const [AppGradients.light],

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.tertiaryLight,
        error: AppColors.error,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.surfaceVariantLight,
        outline: AppColors.borderLight,
      ),

      // Background
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // Typography
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),

      // AppBar theme - Height: 64px, dark purple background with white text
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary, // Dark purple background
        foregroundColor: Colors.white, // White text and icons
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        toolbarHeight: 64, // 64px height as specified
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.primary, // Match AppBar color
          statusBarBrightness: Brightness.dark, // For iOS (light icons)
          statusBarIconBrightness: Brightness.light, // For Android (light icons)
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: Colors.white, // White title text
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // White icons (including back button)
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white, // White action icons
        ),
      ),

      // Card theme - Border radius: 20px (modern), Shadow: elevated (elevation 4), Padding: 16px
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 4, // Modern elevated shadow
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
        ),
        margin: const EdgeInsets.all(16), // 16px padding
      ),

      // Elevated button theme - Primary: Accent color, rounded 12px (modern), 48px height
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Accent color
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48), // 48px height
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
          ),
          elevation: 0,
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Outlined button theme - Secondary: Outlined, same styling (12px radius, 48px height)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 48), // 48px height
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Text button theme - No background, accent text
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary, // Accent text
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input decoration theme - Border radius: 12px (modern), Height: 48px, Focus: accent color border
      // UPDATED: Using warm beige border colors for Mediterranean theme consistency
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        constraints: const BoxConstraints(minHeight: 48), // 48px height
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
          borderSide: const BorderSide(color: AppColors.borderWarmLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.borderWarmLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.primary, width: 2), // Accent color border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryLight),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiaryLight),
      ),

      // Chip theme - selected chips have white text
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantLight,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textPrimaryLight),
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: Colors.white, // White text when selected
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(color: AppColors.dividerLight, thickness: 1, space: 1),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.textTheme.labelSmall,
        unselectedLabelStyle: AppTypography.textTheme.labelSmall,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        ),
        titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(color: AppColors.textPrimaryLight),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8)
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),

      // Switch theme - Primary Purple selected, warm beige unselected
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary; // Purple when selected
          }
          return AppColors.borderWarmLight; // Warm beige when unselected
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.3); // Purple track when selected
          }
          return AppColors.borderWarmLight.withValues(alpha: 0.5); // Warm beige track
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return AppColors.borderWarmLight;
        }),
      ),

      // Popup menu theme - Modern styling
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceLight,
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.sectionDividerLight),
        ),
        textStyle: AppTypography.textTheme.bodyMedium,
      ),

      // Dropdown menu theme - Modern styling
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.textTheme.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfaceLight),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(Colors.black26),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.sectionDividerLight),
            ),
          ),
        ),
      ),

      // Menu theme - For MenuAnchor and MenuBar
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surfaceLight),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(Colors.black26),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.sectionDividerLight),
            ),
          ),
        ),
      ),

      // Date picker theme - Modern styling with brand colors
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceLight,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        dayStyle: AppTypography.textTheme.bodyMedium,
        weekdayStyle: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w600,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.textTertiaryLight;
          return AppColors.textPrimaryLight;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        todayBackgroundColor: WidgetStateProperty.all(AppColors.primary.withAlpha((0.1 * 255).toInt())),
        todayBorder: BorderSide(color: AppColors.primary, width: 1),
        yearStyle: AppTypography.textTheme.bodyLarge,
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textPrimaryLight;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        rangePickerBackgroundColor: AppColors.surfaceLight,
        rangePickerHeaderBackgroundColor: AppColors.primary,
        rangePickerHeaderForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primary.withAlpha((0.2 * 255).toInt()),
        dividerColor: AppColors.sectionDividerLight,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.textSecondaryLight),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );
  }

  // ============================================================================
  // DARK THEME
  // ============================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Gradient extensions
      extensions: const [AppGradients.dark],

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Colors.white, // White text on primary color (chips, buttons)
        primaryContainer: AppColors.primary,
        secondary: AppColors.secondaryLight,
        secondaryContainer: AppColors.secondary,
        tertiary: AppColors.tertiaryLight,
        onTertiary: Colors.black,
        tertiaryContainer: AppColors.tertiary,
        error: AppColors.errorLight,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        outline: AppColors.borderDark,
      ),

      // Background
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // Typography
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),

      // AppBar theme - Height: 64px
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.borderDark,
        toolbarHeight: 64, // 64px height as specified
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.surfaceDark, // Match AppBar color
          statusBarBrightness: Brightness.dark, // For iOS (light icons)
          statusBarIconBrightness: Brightness.light, // For Android (light icons)
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme - Border radius: 20px (modern), Shadow: elevated (elevation 4), Padding: 16px
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 4, // Modern elevated shadow
        shadowColor: AppColors.primaryLight.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
        ),
        margin: const EdgeInsets.all(16), // 16px padding
      ),

      // Elevated button theme - Primary: Accent color, rounded 12px (modern), 48px height
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight, // Accent color
          foregroundColor: Colors.black,
          minimumSize: const Size(0, 48), // 48px height
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
          ),
          elevation: 0,
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Outlined button theme - Secondary: Outlined, same styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size(0, 48), // 48px height
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
          ),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Text button theme - No background, accent text
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight, // Accent text
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // Icon button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          highlightColor: AppColors.primaryLight.withValues(alpha: 0.1),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondaryLight,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input decoration theme - Border radius: 12px (modern), Height: 48px, Focus: accent color border
      // UPDATED: Using warm gray border colors for Mediterranean theme consistency
      // FIXED: Lighter fill color for better contrast and readability
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A), // Lighter than surfaceVariantDark for better contrast
        constraints: const BoxConstraints(minHeight: 48), // 48px height
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius
          borderSide: const BorderSide(color: AppColors.borderWarmDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.borderWarmDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2), // Accent color border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: AppTypography.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondaryDark),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiaryDark),
      ),

      // Chip theme - selected chips have white text
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textPrimaryDark),
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: Colors.white, // White text when selected
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(color: AppColors.dividerDark, thickness: 1, space: 1),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.textTheme.labelSmall,
        unselectedLabelStyle: AppTypography.textTheme.labelSmall,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (upgraded from 16)
        ),
        titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(color: AppColors.textPrimaryDark),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius (upgraded from 8)
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryLight),

      // Switch theme - Primary Purple selected, warm gray unselected
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight; // Light Purple when selected
          }
          return AppColors.borderWarmDark; // Warm gray when unselected
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withValues(alpha: 0.4); // Purple track when selected
          }
          return AppColors.borderWarmDark.withValues(alpha: 0.5); // Warm gray track
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return AppColors.borderWarmDark;
        }),
      ),

      // Popup menu theme - Modern styling (dark mode)
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF252330),
        elevation: 12,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.sectionDividerDark),
        ),
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimaryDark),
      ),

      // Dropdown menu theme - Modern styling (dark mode)
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimaryDark),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF252330)),
          elevation: WidgetStateProperty.all(12),
          shadowColor: WidgetStateProperty.all(Colors.black54),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.sectionDividerDark),
            ),
          ),
        ),
      ),

      // Menu theme - For MenuAnchor and MenuBar (dark mode)
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF252330)),
          elevation: WidgetStateProperty.all(12),
          shadowColor: WidgetStateProperty.all(Colors.black54),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.sectionDividerDark),
            ),
          ),
        ),
      ),

      // Date picker theme - Modern styling with brand colors (dark mode)
      datePickerTheme: DatePickerThemeData(
        backgroundColor: const Color(0xFF1E1E28),
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        dayStyle: AppTypography.textTheme.bodyMedium,
        weekdayStyle: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryDark,
          fontWeight: FontWeight.w600,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) return AppColors.textTertiaryDark;
          return AppColors.textPrimaryDark;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primaryLight),
        todayBackgroundColor: WidgetStateProperty.all(AppColors.primaryLight.withAlpha((0.15 * 255).toInt())),
        todayBorder: BorderSide(color: AppColors.primaryLight, width: 1),
        yearStyle: AppTypography.textTheme.bodyLarge,
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textPrimaryDark;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
          return Colors.transparent;
        }),
        rangePickerBackgroundColor: const Color(0xFF1E1E28),
        rangePickerHeaderBackgroundColor: AppColors.primary,
        rangePickerHeaderForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primaryLight.withAlpha((0.25 * 255).toInt()),
        dividerColor: AppColors.sectionDividerDark,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.textSecondaryDark),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
      ),
    );
  }
}
