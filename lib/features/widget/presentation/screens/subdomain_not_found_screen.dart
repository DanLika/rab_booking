import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../l10n/widget_translations.dart';

/// Screen displayed when a subdomain URL doesn't match any property.
///
/// This screen is shown when:
/// - User navigates to `xxx.view.bookbed.io` but "xxx" is not a valid subdomain
/// - User uses `?subdomain=xxx` query param but "xxx" doesn't exist
///
/// The screen provides:
/// - Clear error message
/// - Explanation of what went wrong
/// - Contact information for support
class SubdomainNotFoundScreen extends ConsumerWidget {
  /// The invalid subdomain that was attempted
  final String subdomain;

  const SubdomainNotFoundScreen({super.key, required this.subdomain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? ColorTokens.dark
        : ColorTokens.light;
    final tr = WidgetTranslations.of(context, ref);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xl),

                  // Title
                  Text(
                    tr.propertyNotFoundTitle,
                    style: GoogleFonts.inter(
                      fontSize: TypographyTokens.fontSizeXXL,
                      fontWeight: TypographyTokens.bold,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpacingTokens.m),

                  // Subdomain display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.m,
                      vertical: SpacingTokens.s,
                    ),
                    decoration: BoxDecoration(
                      color: colors.backgroundTertiary,
                      borderRadius: BorderTokens.circularMedium,
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: Text(
                      subdomain,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: TypographyTokens.fontSizeM,
                        fontWeight: TypographyTokens.medium,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.l),

                  // Explanation
                  Text(
                    tr.propertyNotFoundExplanation,
                    style: GoogleFonts.inter(
                      fontSize: TypographyTokens.fontSizeM,
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpacingTokens.xl),

                  // Contact support
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.l),
                    decoration: BoxDecoration(
                      color: colors.backgroundTertiary,
                      borderRadius: BorderTokens.circularLarge,
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 32,
                          color: colors.primary,
                        ),
                        const SizedBox(height: SpacingTokens.s),
                        Text(
                          tr.needHelp,
                          style: GoogleFonts.inter(
                            fontSize: TypographyTokens.fontSizeM,
                            fontWeight: TypographyTokens.semiBold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Text(
                          tr.contactPropertyOwnerForHelp,
                          style: GoogleFonts.inter(
                            fontSize: TypographyTokens.fontSizeS,
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
