import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyPolicyTitle,
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
              title: l10n.privacyInfoCollectTitle,
              content: l10n.privacyInfoCollectBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyHowWeUseTitle,
              content: l10n.privacyHowWeUseBody,
            ),
            _buildSection(
              context,
              title: l10n.privacySharingInfoTitle,
              content: l10n.privacySharingInfoBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyDataSecurityTitle,
              content: l10n.privacyDataSecurityBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyDataRetentionTitle,
              content: l10n.privacyDataRetentionBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyYourRightsTitle,
              content: l10n.privacyYourRightsBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyCookiesTitle,
              content: l10n.privacyCookiesBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyThirdPartyTitle,
              content: l10n.privacyThirdPartyBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyChildrenTitle,
              content: l10n.privacyChildrenBody,
            ),
            _buildSection(
              context,
              title: l10n.privacyChangesTitle,
              content: l10n.privacyChangesBody,
            ),
            const SizedBox(height: 24),
            _buildContactSection(context),
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

  Widget _buildContactSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.privacyContactTitle,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.privacyContactBody,
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
