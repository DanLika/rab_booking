import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/environment.dart';
import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/gradient_extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../../../shared/widgets/redesign.dart';

/// Subscription Screen
///
/// Platform-aware screen:
/// - WEB: redesigned Pretplata screen (trial hero + billing toggle + Besplatno
///   vs Pro plan comparison) per `design_handoff/screens/08-owner.png`.
/// - NATIVE (Android/iOS): redirect to web dashboard (App Store guidelines
///   require in-app purchases for native-side subscription, BookBed handles
///   payments via web dashboard instead — branch preserved as-is).
///
/// UI-only refactor onto `Bb*` redesign primitives. Subscription / Stripe /
/// payment state machine logic UNTOUCHED.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  /// Local UI state for the Mjesečno / Godišnje toggle.
  /// Default `true` = yearly (handoff lands on "Godišnje −20%").
  bool _yearly = true;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final BBColorSet c = BBColor.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: CommonAppBar(
        title: l10n.subscriptionTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (BuildContext ctx) => Navigator.of(ctx).maybePop(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: kIsWeb
              ? _buildWebContent(context, c, l10n)
              : _buildNativeRedirectContent(context, c, scheme, l10n),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEB — redesigned subscription surface
  // ---------------------------------------------------------------------------

  Widget _buildWebContent(
    BuildContext context,
    BBColorSet c,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 720;
        final double horizontalPad = wide ? BBSpace.lg : BBSpace.sm;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            BBSpace.md,
            horizontalPad,
            BBSpace.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _TrialHero(compact: !wide),
                  const SizedBox(height: BBSpace.md),
                  _BillingToggle(
                    yearly: _yearly,
                    onChanged: (bool v) => setState(() => _yearly = v),
                  ),
                  const SizedBox(height: BBSpace.md),
                  if (wide)
                    _PlansSideBySide(yearly: _yearly, l10n: l10n)
                  else
                    _PlansStacked(yearly: _yearly, l10n: l10n),
                  const SizedBox(height: BBSpace.md),
                  const _FootNote(),
                  const SizedBox(height: BBSpace.lg),
                  BbSectionHeader(title: l10n.subscriptionFaq),
                  _FaqItem(
                    question: l10n.subscriptionFaqTrialEndQuestion,
                    answer: l10n.subscriptionFaqTrialEndAnswer,
                  ),
                  _FaqItem(
                    question: l10n.subscriptionFaqCancelQuestion,
                    answer: l10n.subscriptionFaqCancelAnswer,
                  ),
                  _FaqItem(
                    question: l10n.subscriptionFaqDataSafeQuestion,
                    answer: l10n.subscriptionFaqDataSafeAnswer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // NATIVE — preserved redirect path (logic — DO NOT redesign)
  // ---------------------------------------------------------------------------

  Widget _buildNativeRedirectContent(
    BuildContext context,
    BBColorSet c,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BBSpace.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(BBSpace.md),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.language_rounded,
                size: 64,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: BBSpace.lg),
            Text(
              l10n.subscriptionWebOnlyTitle,
              style: BBType.h1(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpace.sm),
            Text(
              l10n.subscriptionWebOnlyMessage,
              style: BBType.body(context).copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpace.xl),
            BbButton(
              label: l10n.subscriptionContinueToWeb,
              iconLeft: 'open_in_new',
              size: BbButtonSize.lg,
              onPressed: () => _launchWebDashboard(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWebDashboard(BuildContext context) async {
    final Uri uri = Uri.parse(EnvironmentConfig.dashboardBaseUrl);
    try {
      // Note: Don't use canLaunchUrl() - it returns false on Android 11+
      // even when launchUrl() would work. Just try to launch directly.
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open browser. Please visit ${EnvironmentConfig.dashboardHost} manually.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open browser. Please visit ${EnvironmentConfig.dashboardHost} manually.',
            ),
          ),
        );
      }
    }
  }
}

// =============================================================================
// Trial hero — gradient backdrop, eyebrow + title + progress + CTA
// =============================================================================

class _TrialHero extends StatelessWidget {
  const _TrialHero({this.compact = false});

  final bool compact;

  static const int _totalDays = 14;
  static const int _daysLeft = 12;
  static const String _endDate = '10. lipnja 2026.';

  @override
  Widget build(BuildContext context) {
    final BbRedesignTokens rd = BbRedesignTokens.of(context);
    final double progress = _daysLeft / _totalDays;

    final Widget cta = BbButton(
      label: 'Nadogradi na Pro',
      iconLeft: 'workspace_premium',
      variant: BbButtonVariant.onGradientSolid,
      size: compact ? BbButtonSize.md : BbButtonSize.lg,
      fullWidth: compact,
      onPressed: () => _showUpgradeDialog(context),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: rd.heroGradient,
        borderRadius: BBRadius.xlAll,
        boxShadow: rd.purpleGlow,
      ),
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Stack(
        children: <Widget>[
          // Soft white radial halo top-right (decorative).
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                    stops: <double>[0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: _buildBody(context, progress)),
              SizedBox(width: compact ? 0 : 20, height: compact ? 20 : 0),
              if (compact)
                SizedBox(width: double.infinity, child: cta)
              else
                cta,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'VAŠ PLAN',
          style: BBType.eyebrow(
            context,
          ).copyWith(color: const Color(0xD1FFFFFF)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              'Probni period',
              style: BBType.h1(context).copyWith(
                color: Colors.white,
                fontSize: compact ? 22 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.56,
                height: 1.15,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x2EFFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Pro značajke',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        if (!compact) ...<Widget>[
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: BBType.body(
                context,
              ).copyWith(color: const Color(0xD1FFFFFF)),
              children: <InlineSpan>[
                const TextSpan(text: 'Uživate sve Pro mogućnosti. Završava '),
                TextSpan(
                  text: _endDate,
                  style: BBType.body(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: compact ? 12 : 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: compact ? double.infinity : 420,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      style: BBType.caption(context).copyWith(
                        color: const Color(0xE6FFFFFF),
                        fontWeight: FontWeight.w600,
                      ),
                      children: const <InlineSpan>[
                        TextSpan(
                          text: '$_daysLeft',
                          style: TextStyle(
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        TextSpan(text: ' od '),
                        TextSpan(
                          text: '$_totalDays',
                          style: TextStyle(
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        TextSpan(text: ' dana preostalo'),
                      ],
                    ),
                  ),
                  if (compact)
                    Text(
                      'do 10.06.',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: const Color(0xC7FFFFFF)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar.
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: <Widget>[
                      Container(color: const Color(0x38FFFFFF)),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[Colors.white, Color(0xC7FFFFFF)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _showUpgradeDialog(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.subscriptionUpgradeComingSoonTitle),
        content: Text(
          l10n.subscriptionUpgradeComingSoonBody,
          style: TextStyle(color: c.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Billing toggle — Mjesečno / Godišnje (tab-style pill)
// =============================================================================

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _TogglePill(
              label: 'Mjesečno',
              selected: !yearly,
              onTap: () => onChanged(false),
            ),
            _TogglePill(
              label: 'Godišnje',
              selected: yearly,
              onTap: () => onChanged(true),
              discountLabel: '−20%',
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.discountLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? discountLabel;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: BBMotion.adapt(context, BBMotion.fast),
          curve: BBMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? BBShadow.sm : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: BBType.label(context).copyWith(
                  color: selected ? c.textPrimary : c.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (discountLabel != null) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    discountLabel!,
                    style: TextStyle(
                      color: c.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Plan cards — Besplatno vs Pro (side-by-side desktop / stacked mobile)
// =============================================================================

class _PlanFeature {
  const _PlanFeature(this.text, {this.ok = true});
  final String text;
  final bool ok;
}

class _PlansSideBySide extends StatelessWidget {
  const _PlansSideBySide({required this.yearly, required this.l10n});

  final bool yearly;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _FreePlanCard(l10n: l10n)),
          const SizedBox(width: 16),
          Expanded(
            child: _ProPlanCard(yearly: yearly, l10n: l10n),
          ),
        ],
      ),
    );
  }
}

class _PlansStacked extends StatelessWidget {
  const _PlansStacked({required this.yearly, required this.l10n});

  final bool yearly;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProPlanCard(yearly: yearly, l10n: l10n),
        const SizedBox(height: 12),
        _FreeInline(),
      ],
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({required this.l10n});

  final AppLocalizations l10n;

  static const List<_PlanFeature> _features = <_PlanFeature>[
    _PlanFeature('1 smještajna jedinica'),
    _PlanFeature('Osnovni booking widget'),
    _PlanFeature('Email podrška'),
    _PlanFeature('Napredna analitika', ok: false),
    _PlanFeature('AI Asistent', ok: false),
    _PlanFeature('Bez BookBed oznake', ok: false),
  ];

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Besplatno', style: BBType.h2(context)),
              Text(
                'Nakon probe',
                style: BBType.caption(
                  context,
                ).copyWith(color: c.textTertiary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Za prve korake',
            style: BBType.caption(context).copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: 14),
          const _PriceBlock(price: '€0', sub: 'zauvijek', featured: false),
          const SizedBox(height: 16),
          _PlanDivider(color: c.border),
          const SizedBox(height: 16),
          ..._features.map(_FeatureRow.new),
          const SizedBox(height: 18),
          const BbButton(
            label: 'Trenutni plan nakon probe',
            variant: BbButtonVariant.secondary,
            fullWidth: true,
            disabled: true,
          ),
        ],
      ),
    );
  }
}

class _ProPlanCard extends StatelessWidget {
  const _ProPlanCard({required this.yearly, required this.l10n});

  final bool yearly;
  final AppLocalizations l10n;

  static const List<_PlanFeature> _features = <_PlanFeature>[
    _PlanFeature('Neograničeno jedinica'),
    _PlanFeature('Napredna analitika i izvještaji'),
    _PlanFeature('AI Asistent'),
    _PlanFeature('iCal sinkronizacija (Booking, Airbnb)'),
    _PlanFeature('Prioritetna podrška'),
    _PlanFeature('Bez BookBed oznake u widgetu'),
  ];

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final String price = yearly ? '€15' : '€19';

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        BbCard(
          selected: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Pro', style: BBType.h2(context)),
              const SizedBox(height: 2),
              Text(
                'Za ozbiljne iznajmljivače',
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 14),
              _PriceBlock(price: price, sub: '/mjesec', featured: true),
              if (yearly) ...<Widget>[
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                    children: <InlineSpan>[
                      const TextSpan(text: 'Naplaćeno godišnje '),
                      TextSpan(
                        text: '€180',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const TextSpan(text: ' · uštedite '),
                      const TextSpan(
                        text: '€48',
                        style: TextStyle(
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _PlanDivider(color: c.border),
              const SizedBox(height: 16),
              ..._features.map(_FeatureRow.new),
              const SizedBox(height: 18),
              BbButton(
                label: 'Nadogradi na Pro',
                iconLeft: 'workspace_premium',
                fullWidth: true,
                onPressed: () => _TrialHero._showUpgradeDialog(context),
              ),
            ],
          ),
        ),
        // "Preporučeno" badge at top-left overlap.
        Positioned(
          top: -11,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: BBShadow.purpleSm,
            ),
            child: const Text(
              'Preporučeno',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.22,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.price,
    required this.sub,
    required this.featured,
  });

  final String price;
  final String sub;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          price,
          style: BBType.displayNum(context).copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: featured ? c.primary : c.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          sub,
          style: BBType.body(
            context,
          ).copyWith(color: c.textTertiary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _PlanDivider extends StatelessWidget {
  const _PlanDivider({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(height: 1, color: color);
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.f);
  final _PlanFeature f;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          BbIcon(
            name: f.ok ? 'check_circle' : 'cancel',
            size: 18,
            fill: f.ok ? 1 : 0,
            color: f.ok ? c.success : c.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              f.text,
              style: BBType.body(context).copyWith(
                fontSize: 13,
                color: f.ok ? c.textSecondary : c.textTertiary,
                decoration: f.ok ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact mobile-only summary of the free plan that goes below Pro card.
class _FreeInline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return BbCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    style: BBType.label(context).copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    children: const <InlineSpan>[
                      TextSpan(text: 'Besplatno · '),
                      TextSpan(
                        text: '€0',
                        style: TextStyle(
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Plan nakon isteka probe · 1 jedinica',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          BbButton(
            label: 'Zadrži besplatno',
            variant: BbButtonVariant.tertiary,
            size: BbButtonSize.sm,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Foot-note (Stripe security blurb)
// =============================================================================

class _FootNote extends StatelessWidget {
  const _FootNote();

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BBRadius.smAll,
      ),
      child: Row(
        children: <Widget>[
          BbIcon(name: 'verified_user', size: 18, color: c.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: BBType.caption(
                  context,
                ).copyWith(color: c.textTertiary, height: 1.5),
                children: <InlineSpan>[
                  const TextSpan(
                    text:
                        'Sigurno plaćanje putem Stripe-a. Otkažite bilo kada — pretplata se ne obnavlja nakon otkazivanja. ',
                  ),
                  TextSpan(
                    text: 'Usporedi sve značajke',
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FAQ — intentionally retained from existing screen (NOT in handoff design).
// Refactored onto BbCard to stay consistent with the rest of the surface.
// =============================================================================

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: BbCard(
        padding: const EdgeInsets.all(BBSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              question,
              style: BBType.label(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: c.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              answer,
              style: BBType.body(
                context,
              ).copyWith(color: c.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
