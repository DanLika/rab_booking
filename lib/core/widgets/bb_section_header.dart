import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Section header with optional count badge + action link.
class BBSectionHeader extends StatelessWidget {
  const BBSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BBSpace.xs),
      child: Row(
        children: <Widget>[
          Text(title, style: BBType.h3(context)),
          if (count != null) ...<Widget>[
            const SizedBox(width: BBSpace.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpace.xs,
                vertical: BBSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BBRadius.fullAll,
              ),
              child: Text(
                '$count',
                style: BBType.caption(context).copyWith(
                  color: c.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (actionLabel != null && onActionTap != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BBRadius.smAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpace.xs,
                  vertical: BBSpace.xxs,
                ),
                child: Text(
                  actionLabel!,
                  style: BBType.label(context).copyWith(color: c.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
