import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium range slider component with custom styling
/// Features: Gradient track, custom thumbs, labels, text field inputs
class PremiumRangeSlider extends StatefulWidget {
  /// Current range values
  final RangeValues values;

  /// Minimum value
  final double min;

  /// Maximum value
  final double max;

  /// Number of divisions
  final int? divisions;

  /// On change callback
  final ValueChanged<RangeValues>? onChanged;

  /// On change end callback
  final ValueChanged<RangeValues>? onChangeEnd;

  /// Show labels
  final bool showLabels;

  /// Label formatter
  final String Function(double)? labelFormatter;

  /// Currency symbol (if applicable)
  final String? currencySymbol;

  /// Show text inputs
  final bool showTextInputs;

  /// Min input label
  final String minLabel;

  /// Max input label
  final String maxLabel;

  const PremiumRangeSlider({
    super.key,
    required this.values,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.showLabels = true,
    this.labelFormatter,
    this.currencySymbol,
    this.showTextInputs = true,
    this.minLabel = 'Min',
    this.maxLabel = 'Max',
  });

  @override
  State<PremiumRangeSlider> createState() => _PremiumRangeSliderState();
}

class _PremiumRangeSliderState extends State<PremiumRangeSlider> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  late RangeValues _currentValues;

  @override
  void initState() {
    super.initState();
    _currentValues = widget.values;
    _minController = TextEditingController(
      text: _formatValue(widget.values.start),
    );
    _maxController = TextEditingController(
      text: _formatValue(widget.values.end),
    );
  }

  @override
  void didUpdateWidget(PremiumRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _currentValues = widget.values;
      _minController.text = _formatValue(widget.values.start);
      _maxController.text = _formatValue(widget.values.end);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.currencySymbol != null) {
      return value.toStringAsFixed(0);
    }
    return widget.labelFormatter?.call(value) ?? value.toStringAsFixed(0);
  }

  String _formatLabel(double value) {
    final formatted = _formatValue(value);
    if (widget.currencySymbol != null) {
      return '${widget.currencySymbol}$formatted';
    }
    return formatted;
  }

  void _onSliderChanged(RangeValues values) {
    setState(() {
      _currentValues = values;
      _minController.text = _formatValue(values.start);
      _maxController.text = _formatValue(values.end);
    });
    widget.onChanged?.call(values);
  }

  void _onSliderChangeEnd(RangeValues values) {
    widget.onChangeEnd?.call(values);
  }

  void _onMinTextChanged(String value) {
    final numValue = double.tryParse(value);
    if (numValue != null && numValue >= widget.min && numValue < _currentValues.end) {
      final newValues = RangeValues(numValue, _currentValues.end);
      setState(() => _currentValues = newValues);
      widget.onChanged?.call(newValues);
      widget.onChangeEnd?.call(newValues);
    }
  }

  void _onMaxTextChanged(String value) {
    final numValue = double.tryParse(value);
    if (numValue != null && numValue <= widget.max && numValue > _currentValues.start) {
      final newValues = RangeValues(_currentValues.start, numValue);
      setState(() => _currentValues = newValues);
      widget.onChanged?.call(newValues);
      widget.onChangeEnd?.call(newValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Range slider with custom theme
        SliderTheme(
          data: SliderThemeData(
            rangeThumbShape: const _PremiumRangeThumbShape(),
            rangeTrackShape: const _PremiumRangeTrackShape(),
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            valueIndicatorColor: AppColors.primary,
            valueIndicatorTextStyle: AppTypography.small.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.weightSemibold,
            ),
            showValueIndicator: ShowValueIndicator.onDrag,
          ),
          child: RangeSlider(
            values: _currentValues,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            labels: widget.showLabels
                ? RangeLabels(
                    _formatLabel(_currentValues.start),
                    _formatLabel(_currentValues.end),
                  )
                : null,
            onChanged: widget.onChanged != null ? _onSliderChanged : null,
            onChangeEnd: widget.onChangeEnd != null ? _onSliderChangeEnd : null,
          ),
        ),

        if (widget.showTextInputs) ...[
          const SizedBox(height: AppDimensions.spaceM),

          // Text inputs for precise values
          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: _minController,
                  label: widget.minLabel,
                  onSubmitted: _onMinTextChanged,
                  isDark: isDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                ),
                child: Text(
                  '—',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Expanded(
                child: _buildTextInput(
                  controller: _maxController,
                  label: widget.maxLabel,
                  onSubmitted: _onMaxTextChanged,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onSubmitted,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: AppTypography.weightSemibold,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefix: widget.currencySymbol != null
              ? Text(
                  widget.currencySymbol!,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceS,
            vertical: AppDimensions.spaceS,
          ),
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// Custom range thumb shape with shadow
class _PremiumRangeThumbShape extends RangeSliderThumbShape {
  const _PremiumRangeThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;

    // Draw shadow
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw border
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Draw thumb
    canvas.drawCircle(
      center,
      10,
      Paint()..color = Colors.white,
    );
  }
}

/// Custom range track shape with gradient
class _PremiumRangeTrackShape extends RangeSliderTrackShape {
  const _PremiumRangeTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final canvas = context.canvas;
    final inactiveTrackColor = sliderTheme.inactiveTrackColor!;

    // Draw inactive track (left)
    final inactiveLeftPaint = Paint()..color = inactiveTrackColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          trackRect.left,
          trackRect.top,
          startThumbCenter.dx,
          trackRect.bottom,
        ),
        const Radius.circular(AppDimensions.radiusFull),
      ),
      inactiveLeftPaint,
    );

    // Draw active track (middle) with gradient
    final activeGradient = const LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
    );
    final activePaint = Paint()
      ..shader = activeGradient.createShader(
        Rect.fromLTRB(
          startThumbCenter.dx,
          trackRect.top,
          endThumbCenter.dx,
          trackRect.bottom,
        ),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          startThumbCenter.dx,
          trackRect.top,
          endThumbCenter.dx,
          trackRect.bottom,
        ),
        const Radius.circular(AppDimensions.radiusFull),
      ),
      activePaint,
    );

    // Draw inactive track (right)
    final inactiveRightPaint = Paint()..color = inactiveTrackColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          endThumbCenter.dx,
          trackRect.top,
          trackRect.right,
          trackRect.bottom,
        ),
        const Radius.circular(AppDimensions.radiusFull),
      ),
      inactiveRightPaint,
    );
  }
}
