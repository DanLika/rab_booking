import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../auth/presentation/widgets/premium_input_field.dart';
import '../providers/user_profile_provider.dart';

/// Dedicated Bank Account Screen for bank transfer payment settings
class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
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

  void _loadData(UserData userData) {
    if (_originalCompany != null) return;

    _originalCompany = userData.company;
    final company = userData.company;

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
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Molimo ispravno popunite sva polja',
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
      ref.invalidate(userDataProvider);

      if (mounted) {
        setState(() {
          _isDirty = false;
          _isSaving = false;
        });

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Bankovni podaci uspješno spremljeni',
        );

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri spremanju bankovnih podataka',
        );
      }
    }
  }

  Widget _buildBankCard() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerColor.withAlpha((0.4 * 255).toInt()),
              width: 1.5,
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              title: Text(
                'Bankovni Podaci',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Podaci za primanje uplata',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                PremiumInputField(
                  controller: _ibanController,
                  labelText: 'IBAN',
                  prefixIcon: Icons.credit_card,
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  controller: _swiftController,
                  labelText: 'SWIFT/BIC',
                  prefixIcon: Icons.code,
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  controller: _bankNameController,
                  labelText: 'Naziv Banke',
                  prefixIcon: Icons.account_balance,
                ),
                const SizedBox(height: 16),
                PremiumInputField(
                  controller: _accountHolderController,
                  labelText: 'Vlasnik Računa',
                  prefixIcon: Icons.person,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.tertiary.withAlpha((0.1 * 255).toInt()),
        border: Border.all(
          color: theme.colorScheme.tertiary.withAlpha((0.3 * 255).toInt()),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.tertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kada se koriste ovi podaci?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ovi bankovni podaci se prikazuju gostima kada odaberu '
                  '"Bankovni prijenos" kao način plaćanja u booking widget-u.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
              label: Text(_isSaving ? 'Spremanje...' : 'Spremi Promjene'),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor:
                  theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.dividerColor,
                ),
              ),
            ),
            child: const Text('Odustani'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isDirty) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Odbaciti promjene?'),
              content: const Text(
                'Imate nespremljene promjene. Želite li ih odbaciti?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Odustani'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Odbaci'),
                ),
              ],
            ),
          );
          if (shouldPop == true && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: CommonAppBar(
          title: 'Bankovni Račun',
          leadingIcon: Icons.arrow_back,
          onLeadingIconTap: (ctx) => context.pop(),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: context.gradients.pageBackground,
          ),
          child: userDataAsync.when(
            data: (userData) {
              // Create default userData if null
              final effectiveUserData =
                  userData ?? const UserData(profile: UserProfile(userId: ''));

              _loadData(effectiveUserData);

              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 400 ? 16 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Info Card
                          _buildInfoCard(),

                          // Bank Details Card
                          _buildBankCard(),

                          const SizedBox(height: 8),

                          // Action Buttons
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }
}
