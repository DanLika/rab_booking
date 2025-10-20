import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_bookings_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/cancel_booking_dialog.dart';

class UserBookingsScreen extends ConsumerStatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  ConsumerState<UserBookingsScreen> createState() =>
      _UserBookingsScreenState();
}

class _UserBookingsScreenState extends ConsumerState<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje Rezervacije'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nadolazeće'),
            Tab(text: 'Prošle'),
            Tab(text: 'Otkazane'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UpcomingBookingsTab(),
          _PastBookingsTab(),
          _CancelledBookingsTab(),
        ],
      ),
    );
  }
}

class _UpcomingBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(upcomingBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nema nadolazećih rezervacija',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Počni istraživati smještaje',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.search),
                  label: const Text('Pretraži smještaje'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userBookingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return BookingCard(
                booking: booking,
                onTap: () => context.push(
                  '/bookings/${booking.id}',
                ),
                onCancelRequested: booking.canCancel
                    ? () async {
                        await CancelBookingDialog.show(
                          context,
                          booking: booking,
                          onCancelled: () {
                            // Refresh bookings list after successful cancellation
                            ref.invalidate(userBookingsProvider);
                          },
                        );
                      }
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // If error is about RLS/permissions, show friendly message
        final errorMessage = error.toString();
        final isPermissionError = errorMessage.contains('500') ||
            errorMessage.contains('policy') ||
            errorMessage.contains('permission');

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError
                      ? Icons.lock_outline
                      : Icons.error_outline,
                  size: 64,
                  color: isPermissionError ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isPermissionError
                      ? 'Nema dostupnih rezervacija'
                      : 'Greška pri učitavanju',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPermissionError
                      ? 'Možda još nemaš nijednu rezervaciju'
                      : 'Pokušaj ponovo kasnije',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(upcomingBookingsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Osvježi'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.search),
                      label: const Text('Pretraži smještaje'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PastBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(pastBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nema prošlih rezervacija',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tvoje prošle rezervacije će se prikazati ovdje',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userBookingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return BookingCard(
                booking: booking,
                onTap: () => context.push(
                  '/bookings/${booking.id}',
                ),
                onCancelRequested: booking.canCancel
                    ? () async {
                        await CancelBookingDialog.show(
                          context,
                          booking: booking,
                          onCancelled: () {
                            ref.invalidate(userBookingsProvider);
                          },
                        );
                      }
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(pastBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelledBookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(cancelledBookingsProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Nema otkazanih rezervacija',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Otkazane rezervacije će se prikazati ovdje',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userBookingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return BookingCard(
                booking: booking,
                onTap: () => context.push(
                  '/bookings/${booking.id}',
                ),
                onCancelRequested: booking.canCancel
                    ? () async {
                        await CancelBookingDialog.show(
                          context,
                          booking: booking,
                          onCancelled: () {
                            ref.invalidate(userBookingsProvider);
                          },
                        );
                      }
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(cancelledBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
