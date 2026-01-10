import 'package:flutter/material.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/accessibility/accessibility_helpers.dart';
import '../../../../../l10n/app_localizations.dart';

class DialogHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onClose;
  final bool isActionInProgress;

  const DialogHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onClose,
    this.isActionInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    return Container(
      height: ResponsiveDialogUtils.kHeaderHeight,
      padding: EdgeInsets.symmetric(horizontal: headerPadding),
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AccessibleIconButton(
            icon: Icons.close,
            color: Colors.white,
            onPressed: isActionInProgress
                ? null
                : (onClose ?? () => Navigator.of(context).pop()),
            semanticLabel: AppLocalizations.of(context).close,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
