import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_icon.dart';

/// Section title + optional count + trailing link action (handoff [BBSectionHeader]).
class BbSectionHeader extends StatelessWidget {
  const BbSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.onActionTap,
    this.level = BbSectionHeaderLevel.h2,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final BbSectionHeaderLevel level;

  TextStyle _titleStyle(BuildContext context) {
    switch (level) {
      case BbSectionHeaderLevel.h1:
        return BBType.h1(context);
      case BbSectionHeaderLevel.h2:
        return BBType.h2(context);
      case BbSectionHeaderLevel.h3:
        return BBType.h3(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: Text(
                    title,
                    style: _titleStyle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null) ...<Widget>[
                  const SizedBox(width: BBSpace.xs),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '$count',
                      style: BBType.caption(context).copyWith(
                        color: c.textTertiary,
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
          if (actionLabel != null)
            InkWell(
              onTap: onActionTap,
              borderRadius: BBRadius.smAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BBSpace.xs,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      actionLabel!,
                      style: BBType.label(
                        context,
                      ).copyWith(color: c.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    BbIcon(name: 'arrow_forward', size: 16, color: c.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum BbSectionHeaderLevel { h1, h2, h3 }
