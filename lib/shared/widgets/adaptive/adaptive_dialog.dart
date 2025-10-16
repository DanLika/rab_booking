import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';

/// Show an adaptive dialog that adjusts to screen size
///
/// On mobile: Full-screen dialog
/// On desktop: Centered dialog box
///
/// Example:
/// ```dart
/// showAdaptiveDialog(
///   context: context,
///   builder: (context) => AdaptiveDialog(
///     title: 'Confirm',
///     content: Text('Are you sure?'),
///     actions: [
///       TextButton(
///         onPressed: () => Navigator.pop(context, false),
///         child: Text('Cancel'),
///       ),
///       FilledButton(
///         onPressed: () => Navigator.pop(context, true),
///         child: Text('Confirm'),
///       ),
///     ],
///   ),
/// );
/// ```
class AdaptiveDialog extends StatelessWidget {
  const AdaptiveDialog({
    this.title,
    required this.content,
    this.actions = const [],
    super.key,
  });

  /// Dialog title
  final String? title;

  /// Dialog content
  final Widget content;

  /// Dialog actions (buttons)
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    if (isMobile) {
      // Full-screen dialog on mobile
      return Scaffold(
        appBar: AppBar(
          title: title != null ? Text(title!) : null,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
        bottomNavigationBar: actions.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions
                        .map((action) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: action,
                            ))
                        .toList(),
                  ),
                ),
              )
            : null,
      );
    } else {
      // Centered dialog on desktop
      return AlertDialog(
        title: title != null ? Text(title!) : null,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: content,
        ),
        actions: actions,
      );
    }
  }
}

/// Show adaptive dialog helper function
Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final isMobile = Breakpoints.isMobile(context);

  if (isMobile) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: builder,
      ),
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
}
