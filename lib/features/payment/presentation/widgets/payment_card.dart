import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Premium credit card widget with animated card preview
/// Features: Visual card preview, Stripe CardField integration, validation
class PremiumPaymentCard extends StatefulWidget {
  /// Callback when card details change
  final Function(CardFieldInputDetails?) onCardChanged;

  /// Country code for postal code
  final String? countryCode;

  /// Enable postal code
  final bool enablePostalCode;

  /// Show card preview
  final bool showCardPreview;

  const PremiumPaymentCard({
    super.key,
    required this.onCardChanged,
    this.countryCode,
    this.enablePostalCode = true,
    this.showCardPreview = true,
  });

  @override
  State<PremiumPaymentCard> createState() => _PremiumPaymentCardState();
}

class _PremiumPaymentCardState extends State<PremiumPaymentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  CardFieldInputDetails? _cardDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Card Details',
            style: context.isMobile ? AppTypography.h3 : AppTypography.h2,
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // Card preview (optional)
          if (widget.showCardPreview) ...[
            _buildCardPreview(isDark),
            const SizedBox(height: AppDimensions.spaceXL),
          ],

          // Card field container
          PremiumCard.elevated(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card field label
                  Row(
                    children: [
                      const Icon(
                        Icons.credit_card,
                        size: AppDimensions.iconM,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      Text(
                        'Payment Information',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: AppTypography.weightSemibold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spaceL),

                  // Stripe CardField
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.borderColor,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceM,
                      vertical: AppDimensions.spaceS,
                    ),
                    child: CardField(
                      onCardChanged: (card) {
                        setState(() {
                          _cardDetails = card;
                        });
                        widget.onCardChanged(card);
                      },
                      enablePostalCode: widget.enablePostalCode,
                      countryCode: widget.countryCode ?? 'HR',
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceM),

                  // Accepted cards
                  _buildAcceptedCards(),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // Security notice
          _buildSecurityNotice(),
        ],
      ),
    );
  }

  Widget _buildCardPreview(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: _cardDetails?.complete == true
            ? AppColors.primaryGradient
            : LinearGradient(
                colors: [
                  AppColors.withOpacity(AppColors.primary, AppColors.opacity20),
                  AppColors.withOpacity(
                      AppColors.secondary, AppColors.opacity20),
                ],
              ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: _cardDetails?.complete == true
            ? AppShadows.glowPrimary
            : AppShadows.elevation2,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Card brand logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceM,
                  vertical: AppDimensions.spaceS,
                ),
                decoration: BoxDecoration(
                  color: context.textColorInverted.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  _cardDetails?.brand != null
                      ? _getCardBrandName(_cardDetails!.brand)
                      : 'CARD',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textColorInverted,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ),
              Icon(
                Icons.contactless,
                color: context.textColorInverted.withValues(alpha: 0.7),
                size: AppDimensions.iconL,
              ),
            ],
          ),

          // Card number (masked)
          Text(
            _cardDetails?.complete == true
                ? '•••• •••• •••• ${_cardDetails?.last4 ?? '••••'}'
                : '•••• •••• •••• ••••',
            style: AppTypography.h3.copyWith(
              color: context.textColorInverted,
              letterSpacing: 2,
            ),
          ),

          // Card holder and expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: AppTypography.small.copyWith(
                      color: context.textColorInverted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    'YOUR NAME',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColorInverted,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VALID THRU',
                    style: AppTypography.small.copyWith(
                      color: context.textColorInverted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    _cardDetails?.expiryMonth != null &&
                            _cardDetails?.expiryYear != null
                        ? '${_cardDetails!.expiryMonth.toString().padLeft(2, '0')}/${_cardDetails!.expiryYear.toString().substring(2)}'
                        : 'MM/YY',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColorInverted,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedCards() {
    return Builder(
      builder: (context) => Row(
        children: [
          Text(
            'We accept:',
            style: AppTypography.small.copyWith(
              color: context.textColorSecondary,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceS),
          ...['VISA', 'MC', 'AMEX'].map(
            (card) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spaceS),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                  vertical: AppDimensions.spaceXXS,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  card,
                  style: AppTypography.small.copyWith(
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.success, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outlined,
            size: AppDimensions.iconM,
            color: AppColors.success,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  'Your payment information is encrypted and secure. Powered by Stripe.',
                  style: AppTypography.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCardBrandName(String? brand) {
    if (brand == null) return 'CARD';

    switch (brand.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'MASTERCARD';
      case 'amex':
      case 'american express':
        return 'AMEX';
      case 'discover':
        return 'DISCOVER';
      case 'jcb':
        return 'JCB';
      case 'unionpay':
        return 'UNIONPAY';
      case 'diners':
      case 'diners club':
        return 'DINERS';
      default:
        return brand.toUpperCase();
    }
  }
}
