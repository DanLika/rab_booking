import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../theme/responsive_helper.dart';

/// Modern progress indicator showing booking steps
/// Responsive: Desktop (horizontal with labels), Mobile (compact with icons)
/// 4 Steps: Room Selection → Summary → Payment → Confirmation
class BookingProgressIndicator extends ConsumerWidget {
  final WidgetColorScheme colors;
  final int currentStep; // 1, 2, 3, or 4
  final Function(int)? onStepTapped; // Optional navigation callback

  const BookingProgressIndicator({
    super.key,
    required this.colors,
    required this.currentStep,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 16 : 24,
        horizontal: isMobile ? 12 : 24,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        border: Border(bottom: BorderSide(color: colors.borderDefault)),
      ),
      child: isMobile ? _buildMobileProgress() : _buildDesktopProgress(),
    );
  }

  Widget _buildDesktopProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(
          number: 1,
          label: 'SELECT ROOM',
          icon: Icons.calendar_month,
          isActive: currentStep == 1,
          isCompleted: currentStep > 1,
          isMobile: false,
        ),
        _buildConnector(isCompleted: currentStep > 1),
        _buildStep(
          number: 2,
          label: 'SUMMARY',
          icon: Icons.receipt_long,
          isActive: currentStep == 2,
          isCompleted: currentStep > 2,
          isMobile: false,
        ),
        _buildConnector(isCompleted: currentStep > 2),
        _buildStep(
          number: 3,
          label: 'PAYMENT',
          icon: Icons.payment,
          isActive: currentStep == 3,
          isCompleted: currentStep > 3,
          isMobile: false,
        ),
        _buildConnector(isCompleted: currentStep > 3),
        _buildStep(
          number: 4,
          label: 'CONFIRMATION',
          icon: Icons.check_circle,
          isActive: currentStep == 4,
          isCompleted: false,
          isMobile: false,
        ),
      ],
    );
  }

  Widget _buildMobileProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildStep(
            number: 1,
            label: 'Room',
            icon: Icons.calendar_month,
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
            isMobile: true,
          ),
        ),
        _buildConnector(isCompleted: currentStep > 1),
        Expanded(
          child: _buildStep(
            number: 2,
            label: 'Summary',
            icon: Icons.receipt_long,
            isActive: currentStep == 2,
            isCompleted: currentStep > 2,
            isMobile: true,
          ),
        ),
        _buildConnector(isCompleted: currentStep > 2),
        Expanded(
          child: _buildStep(
            number: 3,
            label: 'Payment',
            icon: Icons.payment,
            isActive: currentStep == 3,
            isCompleted: currentStep > 3,
            isMobile: true,
          ),
        ),
        _buildConnector(isCompleted: currentStep > 3),
        Expanded(
          child: _buildStep(
            number: 4,
            label: 'Done',
            icon: Icons.check_circle,
            isActive: currentStep == 4,
            isCompleted: false,
            isMobile: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isCompleted,
    required bool isMobile,
  }) {
    final color = isActive || isCompleted
        ? colors.primary
        : colors.textSecondary;

    // Allow navigation back to completed steps only
    final canNavigate = isCompleted && onStepTapped != null;

    final stepContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle with number/icon/check
        Container(
          width: isMobile ? 40 : 48,
          height: isMobile ? 40 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive || isCompleted
                ? LinearGradient(
                    colors: [colors.primary, colors.primaryHover],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive || isCompleted ? null : colors.backgroundPrimary,
            border: Border.all(color: color, width: isActive ? 3 : 2),
            boxShadow: isActive ? colors.shadowLight : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: isMobile ? 20 : 24,
                    color: colors.textOnPrimary,
                  )
                : isActive
                ? Icon(
                    icon,
                    size: isMobile ? 20 : 24,
                    color: colors.textOnPrimary,
                  )
                : Text(
                    '$number',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Label
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile ? 11 : 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: isMobile ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Active underline
        if (isActive) ...[
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: isMobile ? 30 : 50,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );

    // Wrap with GestureDetector if can navigate back
    if (canNavigate) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onStepTapped!(number),
          child: stepContent,
        ),
      );
    }

    return stepContent;
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          color: isCompleted ? colors.primary : colors.borderDefault,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
