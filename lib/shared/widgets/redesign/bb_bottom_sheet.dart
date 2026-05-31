import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Modal bottom sheet shell (handoff [BBBottomSheet]).
///
/// Pair with `showModalBottomSheet&lt;T&gt;(context: …, isScrollControlled: true,
/// backgroundColor: Colors.transparent, builder: (_) => BbBottomSheet(...))`.
class BbBottomSheet extends StatelessWidget {
  const BbBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.footer,
    this.width,
  });

  final String? title;
  final Widget child;
  final Widget? footer;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return SafeArea(
      top: false,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(BBRadius.lg),
          ),
          boxShadow: BBShadow.modal(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(title!, style: BBType.h3(context)),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                child: child,
              ),
            ),
            if (footer != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
