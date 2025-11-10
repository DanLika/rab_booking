import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/responsive_helper.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Modern booking summary sidebar with responsive design
/// Desktop: Sticky sidebar, Mobile: Full width card
class BookingSummarySidebar extends ConsumerWidget {
  final VoidCallback? onReserve;
  final bool showReserveButton;

  const BookingSummarySidebar({
    super.key,
    this.onReserve,
    this.showReserveButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(selectedRoomProvider);
    final checkIn = ref.watch(checkInDateProvider);
    final checkOut = ref.watch(checkOutDateProvider);
    final adults = ref.watch(adultsCountProvider);
    final children = ref.watch(childrenCountProvider);
    final nights = ref.watch(numberOfNightsProvider);
    final selectedServices = ref.watch(selectedServicesProvider);
    final total = ref.watch(bookingTotalProvider);

    if (room == null) {
      return const SizedBox.shrink();
    }

    // Calculate services total
    double servicesTotal = 0;
    selectedServices.forEach((serviceId, quantity) {
      servicesTotal += 10.0 * quantity; // Simplified, should fetch actual price
    });

    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? SpacingTokens.m : SpacingTokens.l),
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundCard,
        borderRadius: BorderTokens.circularRounded,
        border: Border.fromBorderSide(
          BorderSide(color: ColorTokens.light.borderDefault),
        ),
        boxShadow: ShadowTokens.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Room name header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s2),
            decoration: BoxDecoration(
              color: ColorTokens.light.primarySurface,
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(
                color: ColorTokens.withOpacity(ColorTokens.light.primary, 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.hotel,
                  color: ColorTokens.light.primary,
                  size: IconSizeTokens.medium,
                ),
                const SizedBox(width: SpacingTokens.s),
                Expanded(
                  child: Text(
                    room.name,
                    style: GoogleFonts.inter(
                      fontSize: isMobile
                          ? TypographyTokens.fontSizeL
                          : TypographyTokens.fontSizeXL,
                      fontWeight: TypographyTokens.bold,
                      color: ColorTokens.light.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: IconSizeTokens.large,
                  color: ColorTokens.light.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: SpacingTokens.m2),
          Divider(
            color: ColorTokens.light.borderDefault,
            thickness: BorderTokens.widthThin,
          ),
          const SizedBox(height: SpacingTokens.m),

          // Check-in
          if (checkIn != null) ...[
            _buildInfoRow(
              Icons.login,
              'Check-in',
              DateFormat('E, dd MMM yyyy').format(checkIn),
              'from 14:00',
              isMobile,
            ),
            const SizedBox(height: SpacingTokens.s2),
          ],

          // Check-out
          if (checkOut != null) ...[
            _buildInfoRow(
              Icons.logout,
              'Check-out',
              DateFormat('E, dd MMM yyyy').format(checkOut),
              'to 10:00',
              isMobile,
            ),
            const SizedBox(height: SpacingTokens.s2),
          ],

          // Guests
          _buildInfoRow(
            Icons.people,
            'Guests',
            '$adults ${adults == 1 ? 'adult' : 'adults'}${children > 0 ? ', $children ${children == 1 ? 'child' : 'children'}' : ''}',
            null,
            isMobile,
          ),

          const SizedBox(height: SpacingTokens.m2),
          Divider(
            color: ColorTokens.light.borderDefault,
            thickness: BorderTokens.widthThin,
          ),
          const SizedBox(height: SpacingTokens.m),

          // Pricing breakdown
          Text(
            'Price Breakdown',
            style: GoogleFonts.inter(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: ColorTokens.light.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.s2),

          _buildPriceRow('Number of rooms', '1', isMobile),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow(
            'Price per night',
            '\$${room.pricePerNight.toStringAsFixed(2)}',
            isMobile,
          ),
          const SizedBox(height: SpacingTokens.s),
          _buildPriceRow('Number of nights', '$nights', isMobile),

          if (servicesTotal > 0) ...[
            const SizedBox(height: SpacingTokens.s),
            _buildPriceRow(
              'Additional services',
              '\$${servicesTotal.toStringAsFixed(0)}',
              isMobile,
            ),
          ],

          const SizedBox(height: SpacingTokens.m),
          Divider(
            color: ColorTokens.light.borderDefault,
            thickness: BorderTokens.widthMedium,
          ),
          const SizedBox(height: SpacingTokens.m),

          // Total
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorTokens.azure50, // Very light azure
                  ColorTokens.withOpacity(
                    ColorTokens.azure100,
                    0.9,
                  ), // Light azure
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderTokens.circularMedium,
              border: Border.all(
                color: ColorTokens.withOpacity(ColorTokens.light.primary, 0.3),
                width: BorderTokens.widthMedium,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeXL,
                    fontWeight: TypographyTokens.bold,
                    color: ColorTokens.light.textPrimary,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeHuge,
                    fontWeight: FontWeight.w800,
                    color: ColorTokens.light.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: SpacingTokens.m),

          // Secure shopping badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: IconSizeTokens.small,
                color: ColorTokens.light.success,
              ),
              const SizedBox(width: SpacingTokens.xs2),
              Text(
                'Secure shopping (SSL)',
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeS,
                  fontWeight: TypographyTokens.semiBold,
                  color: ColorTokens.light.success,
                ),
              ),
            ],
          ),

          if (showReserveButton && onReserve != null) ...[
            const SizedBox(height: SpacingTokens.m2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReserve,
                style:
                    ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile
                            ? SpacingTokens.m - 2
                            : SpacingTokens.m,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderTokens.button,
                      ),
                      elevation: 3,
                      shadowColor: ColorTokens.withOpacity(
                        ColorTokens.light.primary,
                        0.4,
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return ColorTokens.light.primaryHover;
                        }
                        return ColorTokens.light.primary;
                      }),
                      foregroundColor: WidgetStatePropertyAll(
                        ColorTokens.light.textOnPrimary,
                      ),
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: IconSizeTokens.medium),
                    const SizedBox(width: SpacingTokens.s),
                    Text(
                      'Reserve Now',
                      style: GoogleFonts.inter(
                        fontSize: TypographyTokens.fontSizeL,
                        fontWeight: TypographyTokens.bold,
                        letterSpacing: TypographyTokens.letterSpacingWide,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    String? subtitle,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(SpacingTokens.s),
          decoration: BoxDecoration(
            color: ColorTokens.light.primarySurface,
            borderRadius: BorderTokens.circularSmall,
          ),
          child: Icon(
            icon,
            size: IconSizeTokens.small,
            color: ColorTokens.light.primary,
          ),
        ),
        const SizedBox(width: SpacingTokens.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeS,
                  fontWeight: TypographyTokens.semiBold,
                  color: ColorTokens.light.textSecondary,
                  letterSpacing: TypographyTokens.letterSpacingWide,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeM,
                  fontWeight: TypographyTokens.semiBold,
                  color: ColorTokens.light.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeXS2,
                    color: ColorTokens.light.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isMobile
                ? TypographyTokens.fontSizeS2
                : TypographyTokens.fontSizeM,
            color: ColorTokens.light.textSecondary,
            fontWeight: TypographyTokens.medium,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isMobile
                ? TypographyTokens.fontSizeS2
                : TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.bold,
            color: ColorTokens.light.textPrimary,
          ),
        ),
      ],
    );
  }
}
