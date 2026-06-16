import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/design/responsive.dart';
import '../../../../core/design/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';

/// About screen — App info, key features, contact & support.
/// Refactored onto Bb* foundation (PR redesign/r4-about).
/// Mirrors Profil #621 settings-family pattern: shell-bg + floating panel
/// + eyebrow header + BbCard sections via BbSectionHeader. AppBar/Scaffold
/// stay legacy per audit/103 §4 (deferred to shell-swap PR).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.aboutTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) => Navigator.of(context).pop(),
      ),
      body: Builder(
        builder: (context) {
          final rd = BbRedesignTokens.of(context);
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          final isDesktop = screenWidth >= 1024;

          // Floating-panel gutter — matches Profil #621.
          final EdgeInsets gutterPadding = isMobile
              ? const EdgeInsets.fromLTRB(8, 4, 8, 16)
              : EdgeInsets.fromLTRB(16, 4, isDesktop ? 28 : 18, 24);

          return Container(
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            // Content clamp — center + cap width so the floating panel doesn't
            // stretch edge-to-edge on tablet/desktop web. See BBContentMaxWidth.
            child: BBContentMaxWidth(
              maxWidth: 1100,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: gutterPadding,
                    child: Container(
                      decoration: BoxDecoration(
                        color: rd.panelBg,
                        borderRadius: BorderRadius.circular(
                          isMobile ? BBRadius.lg : 28,
                        ),
                        border: Border.all(color: rd.panelBorder),
                        boxShadow: rd.panelShadow,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : (isDesktop ? 28 : 22),
                          isMobile ? 16 : 22,
                          isMobile ? 16 : (isDesktop ? 28 : 22),
                          isMobile ? 20 : 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AboutHeader(l10n: l10n, isMobile: isMobile),
                            SizedBox(height: isMobile ? 14 : 18),
                            _AboutIdentityCard(l10n: l10n, isMobile: isMobile),
                            SizedBox(height: isMobile ? 14 : 18),
                            _AboutLayout(
                              isDesktop: isDesktop,
                              description: _AboutDescriptionCard(l10n: l10n),
                              features: _AboutFeaturesCard(l10n: l10n),
                              contact: _AboutContactCard(l10n: l10n),
                            ),
                            SizedBox(height: isMobile ? 18 : 24),
                            _AboutFooter(l10n: l10n),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// Header — eyebrow + h1 (matches Profil #621 _ProfilHeader).
// ============================================================================
class _AboutHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isMobile;

  const _AboutHeader({required this.l10n, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final headlineStyle =
        (isMobile ? BBType.h1(context) : BBType.display(context)).copyWith(
          letterSpacing: -0.6,
          fontWeight: FontWeight.w800,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFO · APLIKACIJA',
          style: BBType.eyebrow(context).copyWith(color: c.primary),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.aboutTitle,
          style: headlineStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

// ============================================================================
// Identity card — BbLogo + app name + tagline. Hero accent strip mirrors
// Profil identity-card pattern (handoff §131).
// ============================================================================
class _AboutIdentityCard extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isMobile;

  const _AboutIdentityCard({required this.l10n, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final rd = BbRedesignTokens.of(context);
    final nameStyle = (isMobile ? BBType.h1(context) : BBType.display(context))
        .copyWith(
          color: c.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        );

    return BbCard(
      padded: false,
      child: ClipRRect(
        borderRadius: BBRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(gradient: rd.heroGradient),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 18 : 24),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BbLogo(size: 56),
                        const SizedBox(height: 14),
                        Text(l10n.aboutAppName, style: nameStyle),
                        const SizedBox(height: 8),
                        Text(
                          l10n.aboutTagline,
                          style: BBType.bodyLg(
                            context,
                          ).copyWith(color: c.textSecondary, height: 1.45),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const BbLogo(size: 72),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.aboutAppName, style: nameStyle),
                              const SizedBox(height: 6),
                              Text(
                                l10n.aboutTagline,
                                style: BBType.bodyLg(context).copyWith(
                                  color: c.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// "Što je BookBed" — description prose in a BbCard.
// ============================================================================
class _AboutDescriptionCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _AboutDescriptionCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbSectionHeader(
            title: l10n.aboutWhatIs,
            level: BbSectionHeaderLevel.h3,
          ),
          Text(
            l10n.aboutDescription,
            style: BBType.body(
              context,
            ).copyWith(color: c.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// "Ključne značajke" — feature rows with BbIcon + title + description.
// ============================================================================
class _AboutFeaturesCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _AboutFeaturesCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final features = <_FeatureSpec>[
      _FeatureSpec(
        icon: 'calendar_today',
        title: l10n.aboutFeatureCalendar,
        description: l10n.aboutFeatureCalendarDesc,
      ),
      _FeatureSpec(
        icon: 'book_online',
        title: l10n.aboutFeatureBookings,
        description: l10n.aboutFeatureBookingsDesc,
      ),
      _FeatureSpec(
        icon: 'sync',
        title: l10n.aboutFeatureIcal,
        description: l10n.aboutFeatureIcalDesc,
      ),
      _FeatureSpec(
        icon: 'payments',
        title: l10n.aboutFeaturePayments,
        description: l10n.aboutFeaturePaymentsDesc,
      ),
      _FeatureSpec(
        icon: 'analytics',
        title: l10n.aboutFeatureAnalytics,
        description: l10n.aboutFeatureAnalyticsDesc,
      ),
    ];

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbSectionHeader(
            title: l10n.aboutKeyFeatures,
            level: BbSectionHeaderLevel.h3,
          ),
          for (int i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: BBSpace.sm),
            _FeatureRow(spec: features[i]),
          ],
        ],
      ),
    );
  }
}

class _FeatureSpec {
  final String icon;
  final String title;
  final String description;

  const _FeatureSpec({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureRow extends StatelessWidget {
  final _FeatureSpec spec;

  const _FeatureRow({required this.spec});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(BBRadius.sm),
          ),
          alignment: Alignment.center,
          child: BbIcon(name: spec.icon, size: 18, color: c.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.title,
                style: BBType.label(
                  context,
                ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                spec.description,
                style: BBType.caption(
                  context,
                ).copyWith(color: c.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// "Kontakt i podrška" — email + website as BbButton(tertiary) + BbIcon.
// External-link launching via existing url_launcher API.
// ============================================================================
class _AboutContactCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _AboutContactCard({required this.l10n});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BbSectionHeader(
            title: l10n.aboutContactSupport,
            level: BbSectionHeaderLevel.h3,
          ),
          _ContactRow(
            label: l10n.aboutEmailLabel,
            value: 'info@bookbed.io',
            icon: 'mail',
            actionIcon: 'open_in_new',
            onTap: () => _launch('mailto:info@bookbed.io'),
          ),
          const SizedBox(height: BBSpace.xs),
          Divider(height: 1, color: c.border.withValues(alpha: 0.6)),
          const SizedBox(height: BBSpace.xs),
          _ContactRow(
            label: l10n.aboutWebsiteLabel,
            value: 'bookbed.io',
            icon: 'language',
            actionIcon: 'open_in_new',
            onTap: () => _launch('https://bookbed.io'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final String actionIcon;
  final VoidCallback onTap;

  const _ContactRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.actionIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Row(
      children: [
        BbIcon(name: icon, size: 18, color: c.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: BBType.body(
                  context,
                ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        BbButton(
          variant: BbButtonVariant.tertiary,
          size: BbButtonSize.sm,
          asIcon: true,
          iconLeft: actionIcon,
          onPressed: onTap,
          semanticLabel: '$label · $value',
        ),
      ],
    );
  }
}

// ============================================================================
// Layout — desktop: 2-col (description + features | contact);
//          mobile/tablet: single column.
// ============================================================================
class _AboutLayout extends StatelessWidget {
  final bool isDesktop;
  final Widget description;
  final Widget features;
  final Widget contact;

  const _AboutLayout({
    required this.isDesktop,
    required this.description,
    required this.features,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [description, const SizedBox(height: 18), features],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(child: contact),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        description,
        const SizedBox(height: 16),
        features,
        const SizedBox(height: 16),
        contact,
      ],
    );
  }
}

// ============================================================================
// Footer — copyright with tabular figures so the year aligns cleanly.
// ============================================================================
class _AboutFooter extends StatelessWidget {
  final AppLocalizations l10n;

  const _AboutFooter({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Center(
      child: Text(
        l10n.aboutCopyright,
        style: BBType.bodyNum(
          context,
        ).copyWith(color: c.textTertiary, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
