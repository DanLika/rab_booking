import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/web_utils.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../shared/utils/ui/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

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
    final dialogBg = isDarkMode
        ? ColorTokens.pureBlack
        : colors.backgroundPrimary;

    // Get WidgetColorScheme for widget-specific colors
    final widgetColors = colors;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderTokens.radiusLarge),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 24),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Text(
              'Popup Blocked',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeL,
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
              'Your browser blocked the payment popup. To complete your booking, please choose one of the options below:',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: SpacingTokens.l),
            _buildOption(
              context: context,
              colors: widgetColors,
              icon: Icons.open_in_new,
              title: 'Open Payment Page',
              description: 'Opens Stripe Checkout in a new tab',
              onTap: () => _handleOpenPaymentPage(context),
            ),
            const SizedBox(height: SpacingTokens.m),
            _buildOption(
              context: context,
              colors: widgetColors,
              icon: Icons.copy,
              title: 'Copy Payment Link',
              description: 'Copy link to share or open manually',
              onTap: () => _handleCopyLink(context, ref),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: SpacingTokens.m),
              _buildOption(
                context: context,
                colors: colors,
                icon: Icons.refresh,
                title: 'Try Again',
                description: 'Allow popups and try opening again',
                onTap: () => _handleRetry(context),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
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
      borderRadius: BorderTokens.circularMedium,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderTokens.circularMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.accent, size: 24),
            const SizedBox(width: SpacingTokens.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
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

  Future<void> _handleCopyLink(BuildContext context, WidgetRef ref) async {
    try {
      await Clipboard.setData(ClipboardData(text: checkoutUrl));
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Payment link copied to clipboard',
        );
      }
    } catch (e) {
      // Clipboard API can fail on some browsers (e.g., Safari in iframe)
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackBarHelper.showError(
          context: context,
          message: 'Could not copy link. Please copy manually.',
        );
      }
    }
  }

  void _handleRetry(BuildContext context) {
    Navigator.of(context).pop();
    onRetry?.call();
  }
}
