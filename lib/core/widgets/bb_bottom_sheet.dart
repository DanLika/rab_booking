import 'package:flutter/material.dart';

import '../design/responsive.dart';
import '../design/tokens.dart';

/// Bottom-sheet primitive with handle-bar + top-rounded [BBRadius.lg],
/// drag-dismiss, bottom safe-area.
///
/// Pair with [BBDialog.show] which auto-routes to this on mobile.
class BBBottomSheet extends StatelessWidget {
  const BBBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;

  /// Show as a modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    List<Widget> actions = const <Widget>[],
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return BBBottomSheet(title: title, actions: actions, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(BBRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          BBSpace.md,
          BBSpace.xs,
          BBSpace.md,
          BBSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: BBSpace.sm),
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BBRadius.fullAll,
                ),
              ),
            ),
            if (title != null) ...<Widget>[
              Text(title!, style: BBType.h2(context)),
              const SizedBox(height: BBSpace.sm),
            ],
            child,
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: BBSpace.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: BBSpace.xs),
                    actions[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered dialog on tablet/desktop. Auto-routes to [BBBottomSheet] on
/// mobile via [BBResponsiveBuilder] inside [show].
class BBDialog extends StatelessWidget {
  const BBDialog({
    super.key,
    this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;

  /// Show as a dialog (tablet+) or bottom-sheet (mobile).
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    List<Widget> actions = const <Widget>[],
    bool barrierDismissible = true,
  }) {
    final BBResponsive r = BBResponsive.of(context);
    if (r.isMobile) {
      return BBBottomSheet.show<T>(
        context: context,
        title: title,
        child: child,
        actions: actions,
        isDismissible: barrierDismissible,
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext ctx) {
        return BBDialog(title: title, actions: actions, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(BBSpace.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(BBSpace.md),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BBRadius.lgAll,
            boxShadow: BBShadow.modal(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (title != null) ...<Widget>[
                Text(title!, style: BBType.h2(context)),
                const SizedBox(height: BBSpace.sm),
              ],
              child,
              if (actions.isNotEmpty) ...<Widget>[
                const SizedBox(height: BBSpace.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    for (int i = 0; i < actions.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: BBSpace.xs),
                      actions[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
