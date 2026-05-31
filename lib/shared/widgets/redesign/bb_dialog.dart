import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';
import 'bb_button.dart';

class BbDialogAction {
  const BbDialogAction({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;
}

/// Modal shell (handoff [BBDialog]).
///
/// Pair with `showDialog<T>(context: ..., builder: (_) => BbDialog(...))`.
class BbDialog extends StatelessWidget {
  const BbDialog({
    super.key,
    required this.title,
    required this.body,
    this.primary,
    this.secondary,
    this.destructive = false,
    this.width = 420,
  });

  final String title;
  final String body;
  final BbDialogAction? primary;
  final BbDialogAction? secondary;
  final bool destructive;
  final double width;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(BBSpace.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BBRadius.lgAll,
            boxShadow: BBShadow.modal(context),
          ),
          padding: const EdgeInsets.all(BBSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, style: BBType.h2(context)),
              const SizedBox(height: BBSpace.xs),
              Text(
                body,
                style: BBType.body(context).copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (secondary != null)
                    BbButton(
                      label: secondary!.label,
                      variant: BbButtonVariant.tertiary,
                      onPressed: secondary!.onPressed,
                    ),
                  if (secondary != null && primary != null)
                    const SizedBox(width: BBSpace.xs),
                  if (primary != null)
                    BbButton(
                      label: primary!.label,
                      variant: destructive
                          ? BbButtonVariant.destructive
                          : BbButtonVariant.primary,
                      onPressed: primary!.onPressed,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
