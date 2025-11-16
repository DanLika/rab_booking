import 'package:flutter/material.dart';

/// A widget that wraps an input field or row of inputs and displays
/// validation errors in an animated container below.
///
/// This ensures consistent spacing and smooth error transitions while
/// keeping input fields at a fixed height.
class ValidatedInputRow extends StatelessWidget {
  /// The child widget (can be a single input or a Row with multiple elements)
  final Widget child;

  /// The error text to display. When null, no error is shown.
  final String? errorText;

  /// Padding for the error text container
  final EdgeInsets errorPadding;

  const ValidatedInputRow({
    super.key,
    required this.child,
    this.errorText,
    this.errorPadding = const EdgeInsets.only(top: 4, left: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: errorText != null ? 20 : 0,
          child: errorText != null
              ? Padding(
                  padding: errorPadding,
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
