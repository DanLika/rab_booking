import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../shared/widgets/redesign.dart';
import '../l10n/widget_translations.dart';
import '../providers/theme_provider.dart';

/// Screen displayed when a subdomain URL doesn't match any property.
///
/// This screen is shown when:
/// - User navigates to `xxx.view.bookbed.io` but "xxx" is not a valid subdomain
/// - User uses `?subdomain=xxx` query param but "xxx" doesn't exist
///
/// The screen provides:
/// - Clear error message
/// - Echo of the invalid subdomain attempted
/// - Contact information for support
///
/// Refactored onto redesign primitives (`Bb*`) per `widget-error.jsx` 404
/// variant. Mint surface mirrors Widget Confirmation #612 — widget is
/// standalone-embeddable, no console shell. Dark mode keeps pure black so the
/// mint accent stays a brand cue rather than a page wash. Subdomain
/// resolution/provider chain UNTOUCHED (see `subdomain_provider`,
/// `fullSlugContextProvider`).
class SubdomainNotFoundScreen extends ConsumerWidget {
  /// The invalid subdomain that was attempted
  final String subdomain;

  const SubdomainNotFoundScreen({super.key, required this.subdomain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);
    final bool isDarkMode = ref.watch(themeProvider);

    // Mirror Widget Confirmation (#612): in dark mode keep pure black so the
    // mint accent stays a brand cue rather than a page wash.
    final Color backgroundColor = isDarkMode ? Colors.black : rd.mintWidget;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BBSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: BbCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // State mark — 88px error-toned disc (mirrors WXMark in
                    // widget-error.jsx). Centered.
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.error.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: BbIcon(
                            name: 'search_off',
                            size: 48,
                            color: c.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: BBSpace.lg),

                    // Title — h1
                    Text(
                      tr.propertyNotFoundTitle,
                      style: BBType.h1(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BBSpace.sm),

                    // Explanation — body, secondary
                    Text(
                      tr.propertyNotFoundExplanation,
                      style: BBType.body(
                        context,
                      ).copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BBSpace.md),

                    // Subdomain echo — JetBrains Mono inside a flat sub-card
                    // (padded:false zeros 20px default; explicit symmetric
                    // padding instead).
                    BbCard(
                      variant: BbCardVariant.flat,
                      padded: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: BBSpace.sm,
                        vertical: BBSpace.xs,
                      ),
                      child: Text(
                        subdomain,
                        style: BBType.mono(
                          context,
                        ).copyWith(color: c.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: BBSpace.lg),

                    // Contact info — accent-left info card (help icon + title
                    // + supporting copy)
                    BbCard(
                      variant: BbCardVariant.accentLeft,
                      accentTone: BbCardAccentTone.info,
                      child: Column(
                        children: <Widget>[
                          BbIcon(
                            name: 'help_outline',
                            size: 32,
                            color: c.primary,
                          ),
                          const SizedBox(height: BBSpace.xs),
                          Text(
                            tr.needHelp,
                            style: BBType.bodyLg(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: BBSpace.xxs),
                          Text(
                            tr.contactPropertyOwnerForHelp,
                            style: BBType.caption(
                              context,
                            ).copyWith(color: c.textSecondary),
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
      ),
    );
  }
}
