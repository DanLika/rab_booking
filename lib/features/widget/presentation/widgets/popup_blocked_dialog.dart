import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/web_utils.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../shared/utils/ui/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../l10n/widget_translations.dart';

/// Dialog shown when Stripe Checkout popup is blocked by browser
/// Provides multiple options for user to proceed with payment
class PopupBlockedDialog extends ConsumerWidget {
  final String checkoutUrl;
  final VoidCallback? onRetry;

  const PopupBlockedDialog({
    super.key,
    required this.checkoutUrl,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final dialogBg = isDarkMode ? Colors.black : colors.backgroundPrimary;

    // Get WidgetColorScheme for widget-specific colors
    final widgetColors = colors;
    final tr = WidgetTranslations.of(context, ref);

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BBRadiusBridges.large),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 24),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Text(
              tr.popupBlockedTitle,
              style: TextStyle(
                fontSize: BBTypeBridges.fontSizeL,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.popupBlockedBody,
              style: TextStyle(
                fontSize: BBTypeBridges.fontSizeM,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: BBSpace.md),
            _buildOption(
              context: context,
              colors: widgetColors,
              icon: Icons.open_in_new,
              title: tr.popupOpenPayment,
              description: tr.popupOpenPaymentDesc,
              onTap: () => _handleOpenPaymentPage(context),
            ),
            const SizedBox(height: BBSpace.sm),
            _buildOption(
              context: context,
              colors: widgetColors,
              icon: Icons.copy,
              title: tr.popupCopyLink,
              description: tr.popupCopyLinkDesc,
              onTap: () => _handleCopyLink(context, tr),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: BBSpace.sm),
              _buildOption(
                context: context,
                colors: colors,
                icon: Icons.refresh,
                title: tr.popupTryAgain,
                description: tr.popupTryAgainDesc,
                onTap: () => _handleRetry(context),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            tr.popupCancel,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required WidgetColorScheme colors,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(
        Radius.circular(BBRadiusBridges.medium),
      ),
      child: Container(
        padding: const EdgeInsets.all(BBSpace.sm),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderDefault),
          borderRadius: const BorderRadius.all(
            Radius.circular(BBRadiusBridges.medium),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.accent, size: 24),
            const SizedBox(width: BBSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: BBTypeBridges.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: BBSpace.xxs),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: BBTypeBridges.fontSizeS,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _handleOpenPaymentPage(BuildContext context) {
    Navigator.of(context).pop();

    // Redirect top-level window (breaks out of iframe)
    if (kIsWeb && isInIframe) {
      redirectTopLevelWindow(checkoutUrl);
    } else {
      // Standalone page - use url_launcher
      launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleCopyLink(
    BuildContext context,
    WidgetTranslations tr,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: checkoutUrl));
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackBarHelper.showSuccess(
          context: context,
          message: tr.popupLinkCopied,
        );
      }
    } catch (e) {
      // Clipboard API can fail on some browsers (e.g., Safari in iframe)
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackBarHelper.showError(context: context, message: tr.popupCopyFailed);
      }
    }
  }

  void _handleRetry(BuildContext context) {
    Navigator.of(context).pop();
    onRetry?.call();
  }
}
