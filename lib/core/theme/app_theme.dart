import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_typography.dart';
import '../constants/app_dimensions.dart';
import '../design/bb_redesign_tokens.dart';

/// Application theme configuration
/// Provides light and dark theme with consistent styling
class AppTheme {
  AppTheme._(); // Private constructor

  // ============================================================================
  // SHARED CONSTANTS (reduce hardcoded color duplication)
  // ============================================================================

  /// Dark mode menu/dropdown background — handoff `panelBg` (BbRedesignTokens
  /// dark) so popup surfaces sit on the same tone as cards.
  /// Used in: popupMenuTheme, dropdownMenuTheme, menuTheme.
  static const Color darkMenuBackground = Color(0xFF0B0B0D);

  /// Dark mode input fill color — same panelBg family as `_darkInputFill`
  /// in `app_gradients.dart`.
  static const Color darkInputFill = Color(0xFF15151A);

  /// Dark mode date picker background — elevated panel one step above
  /// `panelBg` (`#0B0B0D` → `#14141A`) so the modal reads as raised.
  static const Color darkDatePickerBackground = Color(0xFF14141A);

  // ============================================================================
  // LIGHT THEME
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Gradient extensions + redesign-handoff surfaces (Phase 1 additive).
      extensions: const [AppGradients.light, BbRedesignTokens.light],

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

      // Background — shell layer (`--bb-shell-bg`), matches the app bar so
      // screens without an explicit pageBackground paint show no seam.
      scaffoldBackgroundColor: AppColors.shellBgLight,

      // Typography
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),

      // AppBar theme — handoff `BbAppBar`: transparent on the shell
      // (`--bb-shell-bg`), 56px slim, text-primary title, status bar icons
      // dark on light.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.shellBgLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.sectionDividerLight,
        toolbarHeight: 56, // Premium slim AppBar
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: AppColors.shellBgLight,
          statusBarBrightness: Brightness.light, // iOS: dark icons
          statusBarIconBrightness: Brightness.dark, // Android: dark icons
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
          fontSize: 20, // BBType.h2
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondaryLight),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textSecondaryLight,
        ),
      ),

      // Card theme - Border radius: 20px (modern), Shadow: elevated (elevation 4), Padding: 16px
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 4, // Modern elevated shadow
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusM,
          ), // 20px modern radius
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
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusS,
            ), // 12px modern radius
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
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusS,
            ), // 12px modern radius
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
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusS,
          ), // 12px modern radius
          borderSide: const BorderSide(color: AppColors.borderWarmLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.borderWarmLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ), // Accent color border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTypography.textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),

      // Chip theme - selected chips have white text
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantLight,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: Colors.white, // White text when selected
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusM,
          ), // 20px modern radius
        ),
      ),

      // Divider theme - using sectionDivider for better visibility
      dividerTheme: const DividerThemeData(
        color: AppColors.sectionDividerLight,
        thickness: 1,
        space: 1,
      ),

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

      // Dialog theme — Premium (audit/116 §3.3): radius 24 (BBRadius.lg),
      // shadow ramp via Material elevation, bb-h2 title.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 12,
        shadowColor: const Color(0x29101828), // ~16% cool-tone
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL), // 24
        ),
        titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimaryLight,
          fontSize: 20, // BBType.h2
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
      // BottomSheet theme — Premium (audit/116 §3.4): top corners radius 24,
      // surface bg, modal scrim handled by showModalBottomSheet defaults.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        modalBackgroundColor: AppColors.surfaceLight,
        elevation: 12,
        shadowColor: Color(0x29101828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusL),
            topRight: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.borderWarmLight,
      ),

      // Drawer theme — Premium (audit/116 §3.2): surface bg, 280 width,
      // cool-toned envelope shadow approximating `--bb-shadow-lg` (3-layer
      // gets collapsed to Material elevation 16 + cool shadowColor — closest
      // single-stack approximation). Applies to both `drawer` and `endDrawer`
      // (Material draws the same widget class for either slot), so this also
      // premium-ifies the master-panel EndDrawer used by unified_unit_hub.
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceLight,
        scrimColor: Color(0x66101828), // ~40% cool scrim
        elevation: 16,
        shadowColor: Color(0x33101828), // ~20% cool-tone
        surfaceTintColor: Colors.transparent,
        width: 280,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusS,
          ), // 12px modern radius (upgraded from 8)
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

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
            return AppColors.primary.withValues(
              alpha: 0.3,
            ); // Purple track when selected
          }
          return AppColors.borderWarmLight.withValues(
            alpha: 0.5,
          ); // Warm beige track
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
          side: const BorderSide(color: AppColors.sectionDividerLight),
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
              side: const BorderSide(color: AppColors.sectionDividerLight),
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
              side: const BorderSide(color: AppColors.sectionDividerLight),
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
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textTertiaryLight;
          }
          return AppColors.textPrimaryLight;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        todayBackgroundColor: WidgetStateProperty.all(
          AppColors.primary.withAlpha((0.1 * 255).toInt()),
        ),
        todayBorder: const BorderSide(color: AppColors.primary),
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
        rangeSelectionBackgroundColor: AppColors.primary.withAlpha(
          (0.2 * 255).toInt(),
        ),
        dividerColor: AppColors.sectionDividerLight,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryLight,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
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

      // Gradient extensions + redesign-handoff surfaces (Phase 1 additive).
      extensions: const [AppGradients.dark, BbRedesignTokens.dark],

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDarkMode, // mockup --bb-primary dark #8B6FFF
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

      // AppBar theme — handoff `BbAppBar`: transparent on the shell
      // (`--bb-shell-bg` dark = #000), 56px slim, text-primary title,
      // status bar icons light on dark.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.shellBgDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.borderDark,
        toolbarHeight: 56, // Premium slim AppBar
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.shellBgDark,
          statusBarBrightness: Brightness.dark, // iOS: light icons
          statusBarIconBrightness: Brightness.light, // Android: light icons
        ),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 20, // BBType.h2
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondaryDark),
        actionsIconTheme: const IconThemeData(
          color: AppColors.textSecondaryDark,
        ),
      ),

      // Card theme - Border radius: 20px (modern), Shadow: elevated (elevation 4), Padding: 16px
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 4, // Modern elevated shadow
        shadowColor: AppColors.primaryLight.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusM,
          ), // 20px modern radius
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
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusS,
            ), // 12px modern radius
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
            borderRadius: BorderRadius.circular(
              AppDimensions.radiusS,
            ), // 12px modern radius
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
        fillColor:
            darkInputFill, // Lighter than surfaceVariantDark for better contrast
        constraints: const BoxConstraints(minHeight: 48), // 48px height
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusS,
          ), // 12px modern radius
          borderSide: const BorderSide(color: AppColors.borderWarmDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.borderWarmDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ), // Accent color border
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: AppTypography.textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textTertiaryDark,
        ),
      ),

      // Chip theme - selected chips have white text
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: Colors.white, // White text when selected
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusM,
          ), // 20px modern radius
        ),
      ),

      // Divider theme - using sectionDivider for better visibility
      dividerTheme: const DividerThemeData(
        color: AppColors.sectionDividerDark,
        thickness: 1,
        space: 1,
      ),

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

      // Dialog theme — Premium (audit/116 §3.3): radius 24, deeper shadow.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 12,
        shadowColor: const Color(0xCC000000), // 80% black on dark
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL), // 24
        ),
        titleTextStyle: AppTypography.textTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimaryDark,
          fontSize: 20, // BBType.h2
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      // BottomSheet theme — Premium (audit/116 §3.4): top corners radius 24,
      // surface bg.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        elevation: 12,
        shadowColor: Color(0xCC000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusL),
            topRight: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.borderWarmDark,
      ),

      // Drawer theme — Premium (audit/116 §3.2): dark surface, 280 width,
      // deeper envelope shadow for dark contrast. Covers `drawer` + `endDrawer`.
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceDark,
        scrimColor: Color(0x99000000), // 60% black scrim on dark
        elevation: 16,
        shadowColor: Color(0xCC000000),
        surfaceTintColor: Colors.transparent,
        width: 280,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusS,
          ), // 12px modern radius (upgraded from 8)
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
      ),

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
            return AppColors.primaryLight.withValues(
              alpha: 0.4,
            ); // Purple track when selected
          }
          return AppColors.borderWarmDark.withValues(
            alpha: 0.5,
          ); // Warm gray track
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
        color: darkMenuBackground,
        elevation: 12,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.sectionDividerDark),
        ),
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),

      // Dropdown menu theme - Modern styling (dark mode)
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(darkMenuBackground),
          elevation: WidgetStateProperty.all(12),
          shadowColor: WidgetStateProperty.all(Colors.black54),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.sectionDividerDark),
            ),
          ),
        ),
      ),

      // Menu theme - For MenuAnchor and MenuBar (dark mode)
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(darkMenuBackground),
          elevation: WidgetStateProperty.all(12),
          shadowColor: WidgetStateProperty.all(Colors.black54),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.sectionDividerDark),
            ),
          ),
        ),
      ),

      // Date picker theme - Modern styling with brand colors (dark mode)
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkDatePickerBackground,
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
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textTertiaryDark;
          }
          return AppColors.textPrimaryDark;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primaryLight),
        todayBackgroundColor: WidgetStateProperty.all(
          AppColors.primaryLight.withAlpha((0.15 * 255).toInt()),
        ),
        todayBorder: const BorderSide(color: AppColors.primaryLight),
        yearStyle: AppTypography.textTheme.bodyLarge,
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textPrimaryDark;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return Colors.transparent;
        }),
        rangePickerBackgroundColor: darkDatePickerBackground,
        rangePickerHeaderBackgroundColor: AppColors.primary,
        rangePickerHeaderForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primaryLight.withAlpha(
          (0.25 * 255).toInt(),
        ),
        dividerColor: AppColors.sectionDividerDark,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryDark,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
        ),
      ),
    );
  }
}
