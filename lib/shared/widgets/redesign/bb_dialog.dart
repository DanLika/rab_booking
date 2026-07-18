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
///
/// **A11y (audit sweep F2.12):** the dialog scopes and names its route
/// (screen readers announce entry and keep focus inside) and the title
/// carries a heading role. [bodyWidget] renders rich content in place of
/// the plain [body] string — callers no longer have to fall back to a raw
/// `AlertDialog` for icons/lists/forms.
class BbDialog extends StatelessWidget {
  const BbDialog({
    super.key,
    required this.title,
    this.body = '',
    this.bodyWidget,
    this.primary,
    this.secondary,
    this.destructive = false,
    this.width = 420,
  }) : assert(
         body != '' || bodyWidget != null,
         'BbDialog needs a body string or a bodyWidget',
       );

  final String title;
  final String body;

  /// Rich body slot — takes precedence over [body] when non-null.
  final Widget? bodyWidget;

  final BbDialogAction? primary;
  final BbDialogAction? secondary;
  final bool destructive;
  final double width;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    // Raw Dialog has no semanticLabel — scope + name the route explicitly
    // so assistive tech announces the modal and traps traversal (F2.12).
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: _buildDialog(context, c),
    );
  }

  Widget _buildDialog(BuildContext context, BBColorSet c) {
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
              Semantics(
                header: true,
                child: Text(title, style: BBType.h2(context)),
              ),
              const SizedBox(height: BBSpace.xs),
              bodyWidget ??
                  Text(
                    body,
                    style: BBType.body(
                      context,
                    ).copyWith(color: c.textSecondary),
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
