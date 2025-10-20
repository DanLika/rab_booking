import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsAndConditions),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.termsTitle,
              style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.lastUpdated}: ${DateTime.now().year}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: l10n.termsAcceptanceTitle,
              content: l10n.termsAcceptanceBody,
            ),
            _buildSection(
              context,
              title: l10n.termsUseOfServiceTitle,
              content: l10n.termsUseOfServiceBody,
            ),
            _buildSection(
              context,
              title: l10n.termsUserAccountsTitle,
              content: l10n.termsUserAccountsBody,
            ),
            _buildSection(
              context,
              title: l10n.termsBookingsPaymentsTitle,
              content: l10n.termsBookingsPaymentsBody,
            ),
            _buildSection(
              context,
              title: l10n.termsCancellationTitle,
              content: l10n.termsCancellationBody,
            ),
            _buildSection(
              context,
              title: l10n.termsPropertyOwnersTitle,
              content: l10n.termsPropertyOwnersBody,
            ),
            _buildSection(
              context,
              title: l10n.termsGuestResponsibilitiesTitle,
              content: l10n.termsGuestResponsibilitiesBody,
            ),
            _buildSection(
              context,
              title: l10n.termsReviewsRatingsTitle,
              content: l10n.termsReviewsRatingsBody,
            ),
            _buildSection(
              context,
              title: l10n.termsLimitationLiabilityTitle,
              content: l10n.termsLimitationLiabilityBody,
            ),
            _buildSection(
              context,
              title: l10n.termsDisputesTitle,
              content: l10n.termsDisputesBody,
            ),
            _buildSection(
              context,
              title: l10n.termsChangesTitle,
              content: l10n.termsChangesBody,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
