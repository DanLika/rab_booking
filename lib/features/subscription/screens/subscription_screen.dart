import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/environment.dart';
import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/gradient_extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/common_app_bar.dart';
import '../../../shared/widgets/redesign.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/utils/error_display_utils.dart';
import '../data/subscription_repository.dart';
import '../models/trial_status.dart';
import '../providers/trial_status_provider.dart';
import '../utils/stripe_url_guard.dart';

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
/// Shared checkout/portal dispatch for both "Nadogradi na Pro" call sites.
///
/// Resolution order:
/// - already subscribed → Stripe Billing Portal (manage, not double-subscribe;
///   the CF has no server-side double-subscribe guard yet);
/// - price ID for the selected interval empty (staging/prod until the operator
///   creates live prices) → existing "coming soon" dialog, no network call;
/// - otherwise → Checkout Session; the returned URL is only followed when
///   [isSafeStripeUrl] accepts it.
///
/// [redirect] is injectable so tests can spy the destination; production uses
/// a same-tab `launchUrl` (web-only flow — native never reaches this handler).
@visibleForTesting
Future<void> handleSubscriptionCheckoutTap({
  required BuildContext context,
  required SubscriptionRepository repository,
  required bool yearly,
  required bool isSubscribed,
  Future<void> Function(Uri uri)? redirect,
}) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final Future<void> Function(Uri uri) doRedirect =
      redirect ?? (Uri uri) => launchUrl(uri, webOnlyWindowName: '_self');
  // Hash-routed app: the route lives in the fragment, so Stripe's appended
  // `?session_id=...` / `?status=cancelled` lands INSIDE the fragment and the
  // router still opens this screen (see stripeReturnParams for the read side).
  final String returnUrl =
      '${EnvironmentConfig.dashboardBaseUrl}/#/owner/subscription';

  try {
    final String url;
    if (isSubscribed) {
      url = await repository.createPortalSession(returnUrl: returnUrl);
    } else {
      final String priceId = yearly
          ? EnvironmentConfig.stripeProYearlyPriceId
          : EnvironmentConfig.stripeProMonthlyPriceId;
      if (priceId.isEmpty) {
        showUpgradeComingSoonDialog(context);
        return;
      }
      url = await repository.createCheckoutSession(
        priceId: priceId,
        returnUrl: returnUrl,
      );
    }
    if (!isSafeStripeUrl(url)) {
      throw StateError('unsafe redirect URL');
    }
    await doRedirect(Uri.parse(url));
  } catch (e, stackTrace) {
    // Class-2 policy: never surface raw error text to the user.
    await LoggingService.logError(
      'Subscription: checkout/portal dispatch failed',
      e,
      stackTrace,
    );
    if (context.mounted) {
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        isSubscribed
            ? l10n.subscriptionPortalErrorGeneric
            : l10n.subscriptionCheckoutErrorGeneric,
      );
    }
  }
}

/// "Coming soon" dialog — the pre-wiring behavior, kept for environments
/// where subscription prices are not configured yet (empty price ID).
@visibleForTesting
void showUpgradeComingSoonDialog(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => BbDialog(
      title: l10n.subscriptionUpgradeComingSoonTitle,
      body: l10n.subscriptionUpgradeComingSoonBody,
      primary: BbDialogAction(
        label: l10n.ok,
        onPressed: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

/// Stripe-return query params for a hash-routed web app.
///
/// With hash routing the browser URL after a Stripe redirect looks like
/// `https://host/#/owner/subscription?session_id=cs_...` — the params sit in
/// the FRAGMENT, so [Uri.base.queryParameters] alone misses them. Merge both
/// locations (real query wins on key collision is irrelevant here; fragment
/// params are applied last to cover the hash-routing case).
@visibleForTesting
Map<String, String> stripeReturnParams(Uri base) {
  final Map<String, String> merged = <String, String>{...base.queryParameters};
  final String fragment = base.fragment;
  final int q = fragment.indexOf('?');
  if (q >= 0 && q < fragment.length - 1) {
    merged.addAll(Uri.splitQueryString(fragment.substring(q + 1)));
  }
  return merged;
}

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  /// Local UI state for the Mjesečno / Godišnje toggle.
  /// Default `true` = yearly (handoff lands on "Godišnje −20%").
  bool _yearly = true;

  /// Guards double-dispatch while a checkout/portal session is being created.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final Map<String, String> params = stripeReturnParams(Uri.base);
        final AppLocalizations l10n = AppLocalizations.of(context);
        if ((params['session_id'] ?? '').isNotEmpty) {
          // Webhook flips accountStatus → trialStatusProvider stream updates
          // the UI; the snackbar just acknowledges the redirect back.
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.subscriptionPaymentSuccess,
          );
        } else if ((params['status'] ?? '') == 'cancelled') {
          ErrorDisplayUtils.showInfoSnackBar(
            context,
            l10n.subscriptionPaymentCancelled,
          );
        }
      });
    }
  }

  Future<void> _onUpgradeTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    final TrialStatus? status = ref.read(trialStatusProvider).valueOrNull;
    try {
      await handleSubscriptionCheckoutTap(
        context: context,
        repository: ref.read(subscriptionRepositoryProvider),
        yearly: _yearly,
        isSubscribed: status?.isActive ?? false,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                  _TrialHero(compact: !wide, onUpgrade: _onUpgradeTap),
                  const SizedBox(height: BBSpace.md),
                  if (ref.watch(trialStatusProvider).valueOrNull?.isActive ??
                      false) ...<Widget>[
                    BbButton(
                      label: l10n.subscriptionManageLabel,
                      iconLeft: 'credit_card',
                      loading: _busy,
                      onPressed: _onUpgradeTap,
                    ),
                    const SizedBox(height: BBSpace.md),
                  ],
                  _BillingToggle(
                    yearly: _yearly,
                    onChanged: (bool v) => setState(() => _yearly = v),
                  ),
                  const SizedBox(height: BBSpace.md),
                  if (wide)
                    _PlansSideBySide(
                      yearly: _yearly,
                      l10n: l10n,
                      onUpgrade: _onUpgradeTap,
                    )
                  else
                    _PlansStacked(
                      yearly: _yearly,
                      l10n: l10n,
                      onUpgrade: _onUpgradeTap,
                    ),
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

/// Immutable data the trial hero renders. Derived from [TrialStatus] at the
/// call site; exposed for testing so the visual can be pumped without a
/// provider / Firestore stream.
@visibleForTesting
class TrialBarData {
  const TrialBarData({
    required this.daysLeft,
    required this.totalDays,
    required this.endDate,
  });

  /// Whole days remaining, clamped to `[0, totalDays]`.
  final int daysLeft;

  /// Full trial length in whole days (> 0).
  final int totalDays;

  /// Pre-formatted, localized end date (e.g. `10. srpnja 2026.`).
  final String endDate;

  /// `[0.0, 1.0]` fraction of the trial ELAPSED (used for the fill width).
  double get elapsedFraction =>
      totalDays <= 0 ? 0 : ((totalDays - daysLeft) / totalDays).clamp(0.0, 1.0);

  /// Build [TrialBarData] from a live [TrialStatus], or `null` when the bar
  /// must honestly hide (not in trial, or trial bounds not persisted).
  static TrialBarData? fromTrialStatus(
    TrialStatus status,
    String localeName, {
    DateTime? now,
  }) {
    if (!status.isInTrial) return null;
    final int? total = status.totalTrialDays;
    final int? elapsed = status.getDaysElapsed(now: now);
    if (total == null || elapsed == null) return null;
    final DateTime? end = status.trialExpiresAt;
    if (end == null) return null;
    return TrialBarData(
      daysLeft: (total - elapsed).clamp(0, total),
      totalDays: total,
      endDate: DateFormat('d. MMMM yyyy', localeName).format(end),
    );
  }
}

/// Renders the trial hero from resolved [TrialBarData]. Provider-free so tests
/// can pump it directly. Returns `SizedBox.shrink()` for a null [data].
@visibleForTesting
Widget buildTrialHeroForTest({
  required BuildContext context,
  required TrialBarData? data,
  bool compact = false,
  VoidCallback? onUpgrade,
}) => _TrialHero._render(
  context,
  data: data,
  compact: compact,
  onUpgrade: onUpgrade,
);

/// The mobile free-plan summary row (kIsWeb-gated in the live tree, so VM
/// widget tests can't reach it through the screen). Audit F4.3 seam.
@visibleForTesting
Widget buildFreeInlineForTest() => _FreeInline();

/// The Stripe foot-note (same kIsWeb gate). Audit F4.3 seam.
@visibleForTesting
Widget buildFootNoteForTest() => const _FootNote();

class _TrialHero extends ConsumerWidget {
  const _TrialHero({this.compact = false, this.onUpgrade});

  final bool compact;

  /// Real checkout dispatch from the screen; falls back to the coming-soon
  /// dialog when absent (test seam / legacy).
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TrialStatus? status = ref.watch(trialStatusProvider).valueOrNull;
    if (status == null) return const SizedBox.shrink();
    final String localeName = AppLocalizations.of(context).localeName;
    final TrialBarData? data = TrialBarData.fromTrialStatus(status, localeName);
    return _render(context, data: data, compact: compact, onUpgrade: onUpgrade);
  }

  static Widget _render(
    BuildContext context, {
    required TrialBarData? data,
    required bool compact,
    VoidCallback? onUpgrade,
  }) {
    if (data == null) return const SizedBox.shrink();
    final BbRedesignTokens rd = BbRedesignTokens.of(context);
    final double progress = data.elapsedFraction;

    final Widget cta = BbButton(
      label: 'Nadogradi na Pro',
      iconLeft: 'workspace_premium',
      variant: BbButtonVariant.onGradientSolid,
      size: compact ? BbButtonSize.md : BbButtonSize.lg,
      fullWidth: compact,
      onPressed: onUpgrade ?? () => showUpgradeComingSoonDialog(context),
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
              Expanded(child: _buildBody(context, data, progress, compact)),
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

  static Widget _buildBody(
    BuildContext context,
    TrialBarData data,
    double progress,
    bool compact,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.subscriptionTrialEyebrow,
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
          Text(
            l10n.subscriptionTrialEndsInline(data.endDate),
            style: BBType.body(
              context,
            ).copyWith(color: const Color(0xD1FFFFFF)),
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
                  Flexible(
                    child: Text(
                      l10n.subscriptionTrialDaysRemaining(
                        data.daysLeft,
                        data.totalDays,
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: BBType.caption(context).copyWith(
                        color: const Color(0xE6FFFFFF),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  if (compact)
                    Text(
                      l10n.subscriptionTrialEndsShort(data.endDate),
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
  const _PlansSideBySide({
    required this.yearly,
    required this.l10n,
    this.onUpgrade,
  });

  final bool yearly;
  final AppLocalizations l10n;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _FreePlanCard(l10n: l10n)),
          const SizedBox(width: 16),
          Expanded(
            child: _ProPlanCard(
              yearly: yearly,
              l10n: l10n,
              onUpgrade: onUpgrade,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansStacked extends StatelessWidget {
  const _PlansStacked({
    required this.yearly,
    required this.l10n,
    this.onUpgrade,
  });

  final bool yearly;
  final AppLocalizations l10n;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProPlanCard(yearly: yearly, l10n: l10n, onUpgrade: onUpgrade),
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
  const _ProPlanCard({
    required this.yearly,
    required this.l10n,
    this.onUpgrade,
  });

  final bool yearly;
  final AppLocalizations l10n;
  final VoidCallback? onUpgrade;

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
                onPressed:
                    onUpgrade ?? () => showUpgradeComingSoonDialog(context),
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
            // Keeping free needs no server action — declining the upsell
            // just leaves the screen (audit F4.3: was a no-op () {}).
            onPressed: () => Navigator.of(context).maybePop(),
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
          // "Usporedi sve značajke" link removed (audit F4.3): it was a
          // link-styled TextSpan with no recognizer and no comparison
          // surface to point at — both plan cards already list features.
          Expanded(
            child: Text(
              'Sigurno plaćanje putem Stripe-a. Otkažite bilo kada — '
              'pretplata se ne obnavlja nakon otkazivanja.',
              style: BBType.caption(
                context,
              ).copyWith(color: c.textTertiary, height: 1.5),
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
