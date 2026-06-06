import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/universal_loader.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/owner_app_drawer.dart';

/// Dedicated Bank Account screen — refactored onto Bb* redesign primitives
/// (PR redesign/r2c-bank-account). Settings-screen pattern: floating panel
/// inside `OwnerAppDrawer` shell, info banner via `BbCard(variant: accentLeft,
/// info)`, single form card with [BbSectionHeader] + four [BbInput]s.
///
/// Consumer of Phase 1.1 native [BbInput.validator] — IBAN + SWIFT/BIC
/// validators from [ProfileValidators] are wired directly. NOTE: legacy
/// implementation used [PremiumInputField] which accepted no validator, so
/// `_formKey.currentState!.validate()` was effectively a no-op tautology.
/// This refactor makes form validation actually run for the first time
/// (consistent with task mandate "only wire validator into BbInput.validator").
///
/// FROZEN / preserved logic:
///  - `userProfileNotifierProvider.updateCompany` Firestore write path
///  - `companyDetailsProvider` watch + invalidation after save
///  - `_isDirty` dirty-tracking, `PopScope` discard dialog, `_formKey`
///  - Stripe Connect onboarding flow + Stripe API calls — UNTOUCHED
///    (this screen handles legacy bank-transfer fields only; payouts.jsx
///    StripeStatusCard / BalanceTiles / PayoutScheduleCard / RecentPayouts
///    landed in stripe_connect_setup_screen.dart via B4a — see
///    _StripePayoutsDashboard there. BankCard piece is now wired into THIS
///    screen as _buildBankSummaryCard (display card above form, real data).)
///  - [AndroidKeyboardDismissFixApproach1] mixin (per
///    `.claude/rules/keyboard-fix.md`) + `KeyedSubtree(ValueKey('bank_account_…'))`
///  - `resizeToAvoidBottomInset: true`
///  - Parent [Scaffold] + [CommonAppBar] + [OwnerAppDrawer] — NOT swapped
///    (deferred to shell-swap PR per audit/104 §3).
class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen>
    with AndroidKeyboardDismissFixApproach1<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isSaving = false;

  // Bank account controllers
  final _ibanController = TextEditingController();
  final _swiftController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();

  CompanyDetails? _originalCompany;

  @override
  void dispose() {
    _ibanController.dispose();
    _swiftController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  /// Load bank account data from company details
  /// OPTIMIZED: Accepts CompanyDetails directly instead of full UserData
  void _loadData(CompanyDetails company) {
    if (_originalCompany != null) return;

    _originalCompany = company;

    // Load bank fields
    _ibanController.text = company.bankAccountIban;
    _swiftController.text = company.swift;
    _bankNameController.text = company.bankName;
    _accountHolderController.text = company.accountHolder;

    // Add listeners after loading
    _ibanController.addListener(_markDirty);
    _swiftController.addListener(_markDirty);
    _bankNameController.addListener(_markDirty);
    _accountHolderController.addListener(_markDirty);

    setState(() => _isDirty = false);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _saveBankDetails() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          l10n.bankAccountFillFieldsError,
        );
      }
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      // Create updated company details (preserving other fields)
      final updatedCompany = CompanyDetails(
        companyName: _originalCompany?.companyName ?? '',
        taxId: _originalCompany?.taxId ?? '',
        vatId: _originalCompany?.vatId ?? '',
        bankAccountIban: _ibanController.text.trim(),
        swift: _swiftController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountHolder: _accountHolderController.text.trim(),
        address: _originalCompany?.address ?? const Address(),
      );

      // Save company details to Firestore
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateCompany(userId, updatedCompany);

      // Invalidate provider to refresh UI with new data
      ref.invalidate(companyDetailsProvider);

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.bankAccountSaveSuccess,
        );

        // Navigate back to previous page (widget settings embedded in unit-hub)
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(OwnerRoutes.unitHub);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.bankAccountSaveError,
        );
      }
    }
  }

  /// Bank summary display card — shown above form when IBAN is populated.
  /// Premium connected-state surface mirroring payouts.jsx §84 BankCard.
  /// Masked IBAN: first 4 chars + bullets + last 4 chars (e.g. "HR12 ···· 1234").
  Widget _buildBankSummaryCard(
    CompanyDetails company,
    AppLocalizations l10n,
    BBColorSet c,
  ) {
    final iban = company.bankAccountIban.replaceAll(' ', '');
    final masked = _maskIban(iban);
    final holder = company.accountHolder.isNotEmpty
        ? company.accountHolder
        : '—';
    final bank = company.bankName.isNotEmpty
        ? company.bankName
        : l10n.bankAccountBankName;

    return BbCard(
      padded: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BBSpace.md,
          BBSpace.md,
          BBSpace.md,
          BBSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.bankAccountBankDetails,
                    style: BBType.h3(context).copyWith(color: c.textPrimary),
                  ),
                ),
                const BbStatusBadge(
                  status: BbBookingStatus.confirmed,
                  label: 'Aktivan',
                ),
              ],
            ),
            const SizedBox(height: BBSpace.sm),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(BBRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: BbIcon(
                    name: 'account_balance',
                    size: 24,
                    color: c.primary,
                  ),
                ),
                const SizedBox(width: BBSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bank,
                        style: BBType.label(context).copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        masked,
                        style: BBType.mono(
                          context,
                        ).copyWith(color: c.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vlasnik: $holder · EUR',
                        style: BBType.caption(
                          context,
                        ).copyWith(color: c.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _maskIban(String iban) {
    if (iban.length <= 8) return iban;
    final start = iban.substring(0, 4);
    final end = iban.substring(iban.length - 4);
    return '$start ···· ···· ···· $end';
  }

  /// Info banner — replaces legacy [MessageBox.info] with
  /// `BbCard(variant: accentLeft, accentTone: info)` per Phase 2 settings
  /// pattern.
  Widget _buildInfoBanner(AppLocalizations l10n, BBColorSet c) {
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BbIcon(name: 'info', size: 18, color: c.info),
              const SizedBox(width: BBSpace.xs),
              Expanded(
                child: Text(
                  l10n.bankAccountInfoTitle,
                  style: BBType.label(
                    context,
                  ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            l10n.bankAccountInfoDesc,
            style: BBType.body(context).copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Form card — section header + 4× [BbInput] with native `validator:`.
  /// Drops the legacy `ExpansionTile` chrome (decorative; redesign uses flat
  /// cards per payouts.jsx `BankCard`).
  Widget _buildFormCard(AppLocalizations l10n, BBColorSet c) {
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BbSectionHeader(
            title: l10n.bankAccountBankDetails,
            level: BbSectionHeaderLevel.h3,
          ),
          // Phase 1.1 native validator — formerly PremiumInputField w/ no
          // validator (silent no-op on validate()). Validators per
          // ProfileValidators.validateIban / validateSwift; both allow empty
          // (fields are optional) but reject malformed input.
          BbInput(
            key: const ValueKey('bank_account_iban'),
            controller: _ibanController,
            label: l10n.bankAccountIban,
            iconLeft: 'credit_card',
            size: BbInputSize.lg,
            keyboardType: TextInputType.text,
            validator: ProfileValidators.validateIban,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('bank_account_swift'),
            controller: _swiftController,
            label: l10n.bankAccountSwift,
            iconLeft: 'code',
            size: BbInputSize.lg,
            keyboardType: TextInputType.text,
            validator: ProfileValidators.validateSwift,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('bank_account_bank_name'),
            controller: _bankNameController,
            label: l10n.bankAccountBankName,
            iconLeft: 'account_balance',
            size: BbInputSize.lg,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: BBSpace.md),
          BbInput(
            key: const ValueKey('bank_account_holder'),
            controller: _accountHolderController,
            label: l10n.bankAccountHolder,
            iconLeft: 'person',
            size: BbInputSize.lg,
            keyboardType: TextInputType.name,
          ),
          if (l10n.bankAccountBankDetailsSubtitle.isNotEmpty) ...[
            const SizedBox(height: BBSpace.sm),
            Text(
              l10n.bankAccountBankDetailsSubtitle,
              style: BBType.caption(context).copyWith(color: c.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save Button — primary, full-width, lg per Phase 2 settings pattern.
        // Preserves _isDirty enabled-gating; loading state during save.
        BbButton(
          key: const ValueKey('bank_account_save'),
          label: _isSaving
              ? l10n.bankAccountSaving
              : l10n.bankAccountSaveChanges,
          iconLeft: _isSaving ? null : 'save',
          size: BbButtonSize.lg,
          fullWidth: true,
          loading: _isSaving,
          disabled: !_isDirty,
          onPressed: (_isDirty && !_isSaving) ? _saveBankDetails : null,
        ),
        const SizedBox(height: BBSpace.sm),
        // Cancel — secondary (outlined). No delete affordance exists in the
        // legacy implementation; not invented here.
        BbButton(
          key: const ValueKey('bank_account_cancel'),
          label: l10n.bankAccountCancel,
          variant: BbButtonVariant.secondary,
          size: BbButtonSize.lg,
          fullWidth: true,
          onPressed: () {
            // Navigate back to previous page (widget settings embedded in unit-hub)
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(OwnerRoutes.unitHub);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZED: Use companyDetailsProvider instead of userDataProvider
    // This reduces Firestore reads from 2 (profile + company) to 1 (company only)
    final companyDetailsAsync = ref.watch(companyDetailsProvider);
    final l10n = AppLocalizations.of(context);
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isDirty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.bankAccountDiscardTitle),
              content: Text(l10n.bankAccountDiscardDesc),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.bankAccountDiscard),
                ),
              ],
            ),
          );
          if (shouldPop == true && context.mounted) {
            // Navigate back to previous page (widget settings embedded in unit-hub)
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(OwnerRoutes.unitHub);
            }
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('bank_account_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          drawer: const OwnerAppDrawer(
            currentRoute: 'integrations/payments/bank-account',
          ),
          appBar: CommonAppBar(
            title: l10n.bankAccountTitle,
            leadingIcon: Icons.menu,
            onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
          ),
          body: Container(
            color: rd.shellBg,
            child: companyDetailsAsync.when(
              data: (companyDetails) {
                // Create default company if null
                final effectiveCompany =
                    companyDetails ?? const CompanyDetails();

                _loadData(effectiveCompany);

                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                final isDesktop = screenWidth >= 1024;

                // Outer panel gutter — handoff floating console pattern
                // (mirrors profile_screen.dart layout).
                final EdgeInsets gutterPadding = isMobile
                    ? const EdgeInsets.fromLTRB(8, 4, 8, 16)
                    : EdgeInsets.fromLTRB(16, 4, isDesktop ? 28 : 18, 24);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Keyboard-aware minHeight (legacy behaviour preserved
                    // for Android Chrome keyboard mixin co-operation).
                    final mediaQuery = MediaQuery.maybeOf(context);
                    final keyboardHeight =
                        (mediaQuery?.viewInsets.bottom ?? 0.0).clamp(
                          0.0,
                          double.infinity,
                        );
                    final isKeyboardOpen = keyboardHeight > 0;

                    double minHeight;
                    if (isKeyboardOpen &&
                        constraints.maxHeight.isFinite &&
                        constraints.maxHeight > 0) {
                      final calculated = constraints.maxHeight - keyboardHeight;
                      minHeight = calculated.clamp(0.0, constraints.maxHeight);
                    } else {
                      minHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : 0.0;
                    }
                    minHeight = minHeight.isFinite ? minHeight : 0.0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: gutterPadding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
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
                                child: Form(
                                  key: _formKey,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Premium current-state display card —
                                      // only renders when IBAN is populated.
                                      // Mirrors payouts.jsx §84 BankCard with
                                      // masked IBAN + holder · EUR + Aktivan
                                      // badge. Form below remains the edit
                                      // surface (existing behaviour).
                                      if (effectiveCompany
                                          .bankAccountIban
                                          .isNotEmpty) ...[
                                        _buildBankSummaryCard(
                                          effectiveCompany,
                                          l10n,
                                          c,
                                        ),
                                        const SizedBox(height: BBSpace.md),
                                      ],
                                      _buildInfoBanner(l10n, c),
                                      const SizedBox(height: BBSpace.md),
                                      _buildFormCard(l10n, c),
                                      const SizedBox(height: BBSpace.lg),
                                      _buildActionButtons(l10n),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: UniversalLoader.forSection,
              error: (error, stack) =>
                  Center(child: Text('${l10n.error}: $error')),
            ),
          ),
        ),
      ),
    );
  }
}
