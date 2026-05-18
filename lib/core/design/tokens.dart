/// Canonical design tokens for BookBed.
/// New code MUST use BB* tokens. Direct use of AppColors, AppDimensions, etc.
/// is deprecated.
/// See audit/05-design.md Section 8 for migration plan.
library;

import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Spacing scale — delegates to [AppDimensions].
class BBSpace {
  BBSpace._();

  static const double xxs = AppDimensions.spaceXXS;
  static const double xs = AppDimensions.spaceXS;

  // TODO(design-refactor): formalize or eliminate after codemod
  static const double xs2 = 12;

  static const double sm = AppDimensions.spaceS;
  static const double md = AppDimensions.spaceM;
  static const double lg = AppDimensions.spaceL;
  static const double xl = AppDimensions.spaceXL;
  static const double xxl = AppDimensions.spaceXXL;
}

/// Border radius scale — delegates to [AppDimensions].
class BBRadius {
  BBRadius._();

  static const double xs = AppDimensions.radiusXS;

  // TODO(design-refactor): formalize or eliminate after codemod
  static const double xs2 = 8;

  static const double sm = AppDimensions.radiusS;
  static const double md = AppDimensions.radiusM;
  static const double lg = AppDimensions.radiusL;
  static const double xl = AppDimensions.radiusXL;
  static const double full = AppDimensions.radiusFull;
}

/// Color tokens — delegates to [AppColors].
class BBColor {
  BBColor._();

  // Brand
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;

  // Semantic
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  // Surfaces — light
  static const Color bgLight = AppColors.backgroundLight;
  static const Color surfaceLight = AppColors.surfaceLight;
  static const Color surfaceVarLight = AppColors.surfaceVariantLight;
  static const Color sectionDividerLight = AppColors.sectionDividerLight;
  static const Color dialogFooterLight = AppColors.dialogFooterLight;

  // Surfaces — dark
  static const Color bgDark = AppColors.backgroundDark;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color surfaceVarDark = AppColors.surfaceVariantDark;
  static const Color sectionDividerDark = AppColors.sectionDividerDark;
  static const Color dialogFooterDark = AppColors.dialogFooterDark;

  // Text — light
  static const Color textLight = AppColors.textPrimaryLight;
  static const Color textLight2 = AppColors.textSecondaryLight;
  static const Color textLight3 = AppColors.textTertiaryLight;

  // Text — dark
  static const Color textDark = AppColors.textPrimaryDark;
  static const Color textDark2 = AppColors.textSecondaryDark;
  static const Color textDark3 = AppColors.textTertiaryDark;
}

/// Typography size scale (px). AppTypography has no scalar fontSize constants —
/// sizes are embedded inside TextStyle objects. These values match the
/// audit-recommended scale (Section 8) and resolve the fontSize 13/15 sprawl.
class BBType {
  BBType._();

  // TODO(design-refactor): formalize or eliminate after codemod
  static const double xs = 10;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double sm = 12;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double md = 14;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double lg = 16;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double xl = 18;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double xxl = 22;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double display1 = 24;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double display2 = 28;
  // TODO(design-refactor): formalize or eliminate after codemod
  static const double display3 = 32;
}

/// Elevation shadow scale — delegates to [AppShadows].
class BBShadow {
  BBShadow._();

  static const List<BoxShadow> e1 = AppShadows.elevation1;
  static const List<BoxShadow> e2 = AppShadows.elevation2;
  static const List<BoxShadow> e3 = AppShadows.elevation3;
  static const List<BoxShadow> e4 = AppShadows.elevation4;
  static const List<BoxShadow> e5 = AppShadows.elevation5;
}
