import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/message_box.dart';
import '../../../auth/presentation/widgets/premium_input_field.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/universal_loader.dart';

/// Dedicated Bank Account Screen for bank transfer payment settings
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

  Widget _buildBankCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.gradients.sectionBorder),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              iconColor: theme.colorScheme.primary,
              collapsedIconColor: theme.colorScheme.primary,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(
                    (0.12 * 255).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              title: Text(
                l10n.bankAccountBankDetails,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                l10n.bankAccountBankDetailsSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                PremiumInputField(
                  controller: _ibanController,
                  labelText: l10n.bankAccountIban,
                  prefixIcon: Icons.credit_card,
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  controller: _swiftController,
                  labelText: l10n.bankAccountSwift,
                  prefixIcon: Icons.code,
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  controller: _bankNameController,
                  labelText: l10n.bankAccountBankName,
                  prefixIcon: Icons.account_balance,
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  controller: _accountHolderController,
                  labelText: l10n.bankAccountHolder,
                  prefixIcon: Icons.person,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return MessageBox.info(
      title: l10n.bankAccountInfoTitle,
      message: l10n.bankAccountInfoDesc,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Save Button - sa app bar gradient
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Container(
            decoration: BoxDecoration(
              gradient: (_isDirty && !_isSaving)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                    )
                  : null,
              color: (_isDirty && !_isSaving)
                  ? null
                  : theme.disabledColor.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: (_isDirty && !_isSaving) ? _saveBankDetails : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: theme.disabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving
                    ? l10n.bankAccountSaving
                    : l10n.bankAccountSaveChanges,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: () {
              // Navigate back to previous page (widget settings embedded in unit-hub)
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(OwnerRoutes.unitHub);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withAlpha(
                (0.7 * 255).toInt(),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Text(l10n.bankAccountCancel),
          ),
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
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: companyDetailsAsync.when(
              data: (companyDetails) {
                // Create default company if null
                final effectiveCompany =
                    companyDetails ?? const CompanyDetails();

                _loadData(effectiveCompany);

                final isCompact = MediaQuery.of(context).size.width < 400;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Get keyboard height to adjust padding dynamically (with null safety)
                    final mediaQuery = MediaQuery.maybeOf(context);
                    final keyboardHeight =
                        (mediaQuery?.viewInsets.bottom ?? 0.0).clamp(
                          0.0,
                          double.infinity,
                        );
                    final isKeyboardOpen = keyboardHeight > 0;

                    // Calculate minHeight safely - ensure it's always finite and valid
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
                    // Ensure minHeight is always finite (never infinity)
                    minHeight = minHeight.isFinite ? minHeight : 0.0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.all(isCompact ? 16 : 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top content
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Info Card
                                      _buildInfoCard(l10n),

                                      // Bank Details Card
                                      _buildBankCard(l10n),
                                    ],
                                  ),

                                  // Action Buttons (pushed to bottom)
                                  _buildActionButtons(l10n),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => UniversalLoader.forSection(),
              error: (error, stack) =>
                  Center(child: Text('${l10n.error}: $error')),
            ),
          ),
        ),
      ),
    );
  }
}
