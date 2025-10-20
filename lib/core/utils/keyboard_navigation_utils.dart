import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'platform_utils.dart';

/// Keyboard navigation utilities for web and desktop
/// Provides keyboard shortcuts, focus management, and accessibility
class KeyboardNavigationUtils {
  KeyboardNavigationUtils._();

  /// Check if keyboard shortcuts are enabled for this platform
  static bool get isEnabled => PlatformUtils.supportsKeyboard;

  /// Common keyboard shortcuts
  static const enterKey = LogicalKeyboardKey.enter;
  static const spaceKey = LogicalKeyboardKey.space;
  static const escapeKey = LogicalKeyboardKey.escape;
  static const tabKey = LogicalKeyboardKey.tab;
  static const arrowUpKey = LogicalKeyboardKey.arrowUp;
  static const arrowDownKey = LogicalKeyboardKey.arrowDown;
  static const arrowLeftKey = LogicalKeyboardKey.arrowLeft;
  static const arrowRightKey = LogicalKeyboardKey.arrowRight;

  /// Request focus on a widget
  static void requestFocus(BuildContext context, FocusNode node) {
    if (isEnabled) {
      FocusScope.of(context).requestFocus(node);
    }
  }

  /// Unfocus current focus
  static void unfocus(BuildContext context) {
    if (isEnabled) {
      FocusScope.of(context).unfocus();
    }
  }

  /// Move focus to next element
  static void focusNext(BuildContext context) {
    if (isEnabled) {
      FocusScope.of(context).nextFocus();
    }
  }

  /// Move focus to previous element
  static void focusPrevious(BuildContext context) {
    if (isEnabled) {
      FocusScope.of(context).previousFocus();
    }
  }
}

/// Widget that handles keyboard shortcuts
class KeyboardShortcut extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// Key to listen for
  final LogicalKeyboardKey shortcutKey;

  /// Callback when key is pressed
  final VoidCallback onPressed;

  /// Require Control/Command key
  final bool requireControl;

  /// Require Shift key
  final bool requireShift;

  /// Require Alt key
  final bool requireAlt;

  const KeyboardShortcut({
    super.key,
    required this.child,
    required this.shortcutKey,
    required this.onPressed,
    this.requireControl = false,
    this.requireShift = false,
    this.requireAlt = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!KeyboardNavigationUtils.isEnabled) {
      return child;
    }

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == shortcutKey) {
          final controlPressed = HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
          final altPressed = HardwareKeyboard.instance.isAltPressed;

          if ((requireControl && !controlPressed) ||
              (requireShift && !shiftPressed) ||
              (requireAlt && !altPressed)) {
            return KeyEventResult.ignored;
          }

          if (!requireControl && controlPressed) {
            return KeyEventResult.ignored;
          }
          if (!requireShift && shiftPressed) {
            return KeyEventResult.ignored;
          }
          if (!requireAlt && altPressed) {
            return KeyEventResult.ignored;
          }

          onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Focusable button with keyboard support
class KeyboardFocusableButton extends StatefulWidget {
  /// Child widget
  final Widget child;

  /// Tap callback
  final VoidCallback onTap;

  /// Focus node (optional)
  final FocusNode? focusNode;

  /// Auto focus
  final bool autofocus;

  /// Show focus indicator
  final bool showFocusIndicator;

  /// Focus indicator color
  final Color? focusColor;

  const KeyboardFocusableButton({
    super.key,
    required this.child,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.showFocusIndicator = true,
    this.focusColor,
  });

  @override
  State<KeyboardFocusableButton> createState() =>
      _KeyboardFocusableButtonState();
}

class _KeyboardFocusableButtonState extends State<KeyboardFocusableButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        widget.onTap();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!KeyboardNavigationUtils.isEnabled) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    Widget child = GestureDetector(
      onTap: widget.onTap,
      child: widget.child,
    );

    if (widget.showFocusIndicator && _isFocused) {
      child = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.focusColor ?? Theme.of(context).primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}

/// Dismissible with Escape key
class KeyboardDismissible extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// Callback when dismissed
  final VoidCallback onDismiss;

  const KeyboardDismissible({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!KeyboardNavigationUtils.isEnabled) {
      return child;
    }

    return KeyboardShortcut(
      shortcutKey: KeyboardNavigationUtils.escapeKey,
      onPressed: onDismiss,
      child: child,
    );
  }
}

/// Focus scope with tab order management
class TabOrderScope extends StatelessWidget {
  /// Children widgets
  final List<Widget> children;

  /// Axis direction
  final Axis direction;

  const TabOrderScope({
    super.key,
    required this.children,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    if (!KeyboardNavigationUtils.isEnabled) {
      return direction == Axis.vertical
          ? Column(children: children)
          : Row(children: children);
    }

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: direction == Axis.vertical
          ? Column(children: children)
          : Row(children: children),
    );
  }
}

/// Accessible button with proper semantics and keyboard support
class AccessibleButton extends StatelessWidget {
  /// Child widget
  final Widget child;

  /// Tap callback
  final VoidCallback onTap;

  /// Semantic label
  final String? semanticLabel;

  /// Tooltip
  final String? tooltip;

  /// Focus node
  final FocusNode? focusNode;

  /// Auto focus
  final bool autofocus;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = KeyboardFocusableButton(
      onTap: onTap,
      focusNode: focusNode,
      autofocus: autofocus,
      child: child,
    );

    if (semanticLabel != null) {
      button = Semantics(
        button: true,
        label: semanticLabel,
        child: button,
      );
    }

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Grid with arrow key navigation
class KeyboardNavigableGrid extends StatefulWidget {
  /// Items to display
  final List<Widget> children;

  /// Number of columns
  final int crossAxisCount;

  /// Item builder with focus state
  final Widget Function(Widget child, bool isFocused) itemBuilder;

  /// Callback when item is selected
  final void Function(int index)? onItemSelected;

  const KeyboardNavigableGrid({
    super.key,
    required this.children,
    required this.crossAxisCount,
    required this.itemBuilder,
    this.onItemSelected,
  });

  @override
  State<KeyboardNavigableGrid> createState() => _KeyboardNavigableGridState();
}

class _KeyboardNavigableGridState extends State<KeyboardNavigableGrid> {
  int _focusedIndex = 0;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.children.length,
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int delta) {
    setState(() {
      _focusedIndex = (_focusedIndex + delta).clamp(0, widget.children.length - 1);
      _focusNodes[_focusedIndex].requestFocus();
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _moveFocus(1);
        break;
      case LogicalKeyboardKey.arrowLeft:
        _moveFocus(-1);
        break;
      case LogicalKeyboardKey.arrowDown:
        _moveFocus(widget.crossAxisCount);
        break;
      case LogicalKeyboardKey.arrowUp:
        _moveFocus(-widget.crossAxisCount);
        break;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        widget.onItemSelected?.call(_focusedIndex);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!KeyboardNavigationUtils.isEnabled) {
      return GridView.count(
        crossAxisCount: widget.crossAxisCount,
        children: widget.children
            .map((child) => widget.itemBuilder(child, false))
            .toList(),
      );
    }

    return Focus(
      onKeyEvent: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.handled;
      },
      child: GridView.count(
        crossAxisCount: widget.crossAxisCount,
        children: List.generate(
          widget.children.length,
          (index) => Focus(
            focusNode: _focusNodes[index],
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                setState(() => _focusedIndex = index);
              }
            },
            child: widget.itemBuilder(
              widget.children[index],
              _focusedIndex == index,
            ),
          ),
        ),
      ),
    );
  }
}
