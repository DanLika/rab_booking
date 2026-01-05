import 'package:flutter/material.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/input_decoration_helper.dart';

/// Search text field with debouncing
///
/// This widget provides a search input field that debounces user input
/// to avoid excessive API calls or expensive operations.
///
/// Example:
/// ```dart
/// DebouncedSearchField(
///   hintText: 'Pretraži smještaje...',
///   onSearch: (query) {
///     // This will only be called 500ms after user stops typing
///     searchRepository.search(query);
///   },
///   debounceDelay: Duration(milliseconds: 500),
/// )
/// ```
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    required this.onSearch,
    this.hintText = 'Pretraži...',
    this.debounceDelay = const Duration(milliseconds: 500),
    this.prefixIcon = Icons.search,
    this.initialValue,
    this.onClear,
    this.enabled = true,
    super.key,
  });

  /// Callback when search query changes (after debounce)
  final ValueChanged<String> onSearch;

  /// Placeholder text
  final String hintText;

  /// Delay before triggering search
  final Duration debounceDelay;

  /// Icon to show at start of field
  final IconData prefixIcon;

  /// Initial search value
  final String? initialValue;

  /// Callback when clear button is pressed
  final VoidCallback? onClear;

  /// Whether the field is enabled
  final bool enabled;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller;
  late final Debouncer _debouncer;
  // SF-015: Use ValueNotifier to avoid rebuilding the whole widget on every keystroke
  late final ValueNotifier<bool> _showClearButtonNotifier;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _debouncer = Debouncer(delay: widget.debounceDelay);
    _showClearButtonNotifier = ValueNotifier<bool>(_controller.text.isNotEmpty);

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _debouncer.dispose();
    _showClearButtonNotifier.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // SF-015: Only update the notifier, no need for setState
    _showClearButtonNotifier.value = _controller.text.isNotEmpty;

    // Debounce the search callback
    _debouncer.run(() {
      widget.onSearch(_controller.text);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => TextField(
        controller: _controller,
        enabled: widget.enabled,
        decoration:
            InputDecorationHelper.buildDecoration(
              labelText: widget.hintText,
              prefixIcon: Icon(widget.prefixIcon),
              context: ctx,
            ).copyWith(
              // SF-015: Use ValueListenableBuilder to rebuild only the clear button
              suffixIcon: ValueListenableBuilder<bool>(
                valueListenable: _showClearButtonNotifier,
                builder: (context, showClear, child) {
                  return showClear
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch, tooltip: 'Očisti')
                      : const SizedBox.shrink();
                },
              ),
            ),
        onSubmitted: (_) {
          // Cancel debounce and trigger immediately on submit
          _debouncer.cancel();
          widget.onSearch(_controller.text);
        },
      ),
    );
  }
}

/// Compact search field for use in app bars
class CompactDebouncedSearchField extends StatefulWidget {
  const CompactDebouncedSearchField({
    required this.onSearch,
    this.hintText = 'Pretraži...',
    this.debounceDelay = const Duration(milliseconds: 500),
    this.initialValue,
    this.onClose,
    super.key,
  });

  final ValueChanged<String> onSearch;
  final String hintText;
  final Duration debounceDelay;
  final String? initialValue;
  final VoidCallback? onClose;

  @override
  State<CompactDebouncedSearchField> createState() => _CompactDebouncedSearchFieldState();
}

class _CompactDebouncedSearchFieldState extends State<CompactDebouncedSearchField> {
  late final TextEditingController _controller;
  late final Debouncer _debouncer;
  late final FocusNode _focusNode;
  // SF-015: Use ValueNotifier to avoid rebuilding the whole widget on every keystroke
  late final ValueNotifier<bool> _showClearButtonNotifier;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _debouncer = Debouncer(delay: widget.debounceDelay);
    _focusNode = FocusNode();
    _showClearButtonNotifier = ValueNotifier<bool>(_controller.text.isNotEmpty);

    _controller.addListener(_onTextChanged);

    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _debouncer.dispose();
    _focusNode.dispose();
    _showClearButtonNotifier.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // SF-015: Only update the notifier, no need for setState
    _showClearButtonNotifier.value = _controller.text.isNotEmpty;

    _debouncer.run(() {
      widget.onSearch(_controller.text);
    });
  }

  void _close() {
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SF-015: Use ValueListenableBuilder to rebuild only the clear button
            ValueListenableBuilder<bool>(
              valueListenable: _showClearButtonNotifier,
              builder: (context, showClear, child) {
                if (!showClear) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                  },
                  tooltip: 'Očisti',
                );
              },
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: _close, tooltip: 'Zatvori pretragu'),
          ],
        ),
      ),
      onSubmitted: (_) {
        _debouncer.cancel();
        widget.onSearch(_controller.text);
      },
    );
  }
}
