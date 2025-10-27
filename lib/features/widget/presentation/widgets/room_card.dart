import 'package:flutter/material.dart';
import '../../../../shared/models/unit_model.dart';
import '../theme/bedbooking_theme.dart';

/// Room card displaying room info, image, amenities, and price
class RoomCard extends StatelessWidget {
  final UnitModel room;
  final VoidCallback onSelect;
  final String? badge;

  const RoomCard({
    super.key,
    required this.room,
    required this.onSelect,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BedBookingCards.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room image
          Stack(
            children: [
              Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: room.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        child: Image.network(
                          room.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.hotel, size: 48, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.hotel, size: 48, color: Colors.grey),
                      ),
              ),
              // Info icon overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: BedBookingColors.textDark,
                  ),
                ),
              ),
            ],
          ),

          // Room details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BedBookingColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: BedBookingColors.primaryGreen,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: BedBookingTextStyles.small.copyWith(
                          color: BedBookingColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Room name
                  Text(
                    room.name,
                    style: BedBookingTextStyles.heading2,
                  ),
                  const SizedBox(height: 12),

                  // Capacity and beds info
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: BedBookingColors.textGrey),
                      const SizedBox(width: 6),
                      Text(
                        '${room.maxGuests} + 2 extra beds',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bed, size: 16, color: BedBookingColors.textGrey),
                      const SizedBox(width: 6),
                      Text(
                        '2 double beds',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bed, size: 16, color: BedBookingColors.textGrey),
                      const SizedBox(width: 6),
                      Text(
                        '2 single beds',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (room.areaSqm != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.square_foot, size: 16, color: BedBookingColors.textGrey),
                        const SizedBox(width: 6),
                        Text(
                          '${room.areaSqm} m²',
                          style: BedBookingTextStyles.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Amenities icons
                  Row(
                    children: [
                      _buildAmenityIcon(Icons.local_parking, 'Parking'),
                      const SizedBox(width: 8),
                      _buildAmenityIcon(Icons.ac_unit, 'AC'),
                      const SizedBox(width: 8),
                      _buildAmenityIcon(Icons.wifi, 'WiFi'),
                      const SizedBox(width: 8),
                      _buildAmenityIcon(Icons.accessible, 'Accessible'),
                      const SizedBox(width: 8),
                      _buildAmenityIcon(Icons.smoke_free, 'Non-smoking'),
                      const SizedBox(width: 8),
                      _buildAmenityIcon(Icons.luggage, 'Luggage'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price
                  Text(
                    '\$${room.pricePerNight.toStringAsFixed(2)} USD',
                    style: BedBookingTextStyles.price,
                  ),
                  Text(
                    '\$${room.pricePerNight.toStringAsFixed(2)} USD per night',
                    style: BedBookingTextStyles.small,
                  ),

                  const SizedBox(height: 16),

                  // Select button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: BedBookingButtons.primaryButton,
                      child: const Text('Select'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 20,
        color: BedBookingColors.primaryGreen,
      ),
    );
  }
}
