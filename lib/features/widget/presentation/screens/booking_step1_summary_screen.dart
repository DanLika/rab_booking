import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';
import '../widgets/additional_service_selector.dart';
import '../widgets/booking_summary_sidebar.dart';
import '../widgets/progress_indicator_widget.dart';

/// Step 1: Summary & Additional Services screen
class BookingStep1SummaryScreen extends ConsumerWidget {
  const BookingStep1SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(selectedRoomProvider);

    if (room == null) {
      // Navigate back if no room selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookingStepProvider.notifier).state = 0;
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: BedBookingColors.backgroundWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout(context, ref, room);
          } else {
            return _buildDesktopLayout(context, ref, room);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, dynamic room) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildContent(context, ref, room),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: BookingSummarySidebar(
              showReserveButton: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, dynamic room) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content
        Expanded(
          child: SingleChildScrollView(
            child: _buildContent(context, ref, room),
          ),
        ),

        // Sidebar
        Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          child: const BookingSummarySidebar(
            showReserveButton: false,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic room) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          const BookingProgressIndicator(currentStep: 1),
          const SizedBox(height: 40),

          // Summary heading
          const Text(
            'Summary',
            style: BedBookingTextStyles.heading1,
          ),
          const SizedBox(height: 24),

          // Room info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BedBookingCards.cardDecoration,
            child: Row(
              children: [
                // Room image
                if (room.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      room.images.first,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[300],
                          child: const Icon(Icons.hotel, size: 48),
                        );
                      },
                    ),
                  ),
                const SizedBox(width: 20),

                // Room name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: BedBookingTextStyles.heading2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Property location (placeholder - would fetch from property)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BedBookingColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: BedBookingColors.textGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rocky Resort *DEMO*',
                        style: BedBookingTextStyles.bodyBold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rab, Croatia',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Additional services
          const Text(
            'Additional services',
            style: BedBookingTextStyles.heading2,
          ),
          const SizedBox(height: 16),

          // Additional services (demo - would fetch from repository in production)
          Text(
            'No additional services available for this demo',
            style: BedBookingTextStyles.bodyGrey,
          ),

          const SizedBox(height: 40),

          // Navigation buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  ref.read(bookingStepProvider.notifier).state = 0;
                },
                style: BedBookingButtons.secondaryButton,
                child: const Text('Back'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ref.read(bookingStepProvider.notifier).state = 2;
                },
                style: BedBookingButtons.primaryButton,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
