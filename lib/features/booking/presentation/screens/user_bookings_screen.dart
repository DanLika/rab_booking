import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_bookings_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';

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
        children: const [
          _UpcomingBookingsTab(),
          _PastBookingsTab(),
          _CancelledBookingsTab(),
        ],
      ),
    );
  }
}

class _UpcomingBookingsTab extends ConsumerWidget {
  const _UpcomingBookingsTab();

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
                  size: AppDimensions.iconXL,
                  color: Colors.grey[400],
                ),
                SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Nema nadolazećih rezervacija',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: AppDimensions.spaceXS),
                Text(
                  'Počni istraživati smještaje',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                SizedBox(height: AppDimensions.spaceM),
                Semantics(
                  label: 'Pretraži smještaje',
                  hint: 'Dvostruki dodir za pregled dostupnih smještaja',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.search),
                    label: const Text('Pretraži smještaje'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
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
            padding: EdgeInsets.all(context.horizontalPadding),
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
      loading: () => ListView.builder(
        padding: EdgeInsets.all(context.horizontalPadding),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppDimensions.spaceS),
          child: const BookingCardSkeleton(),
        ),
      ),
      error: (error, stack) {
        // If error is about RLS/permissions, show friendly message
        final errorMessage = error.toString();
        final isPermissionError = errorMessage.contains('500') ||
            errorMessage.contains('policy') ||
            errorMessage.contains('permission');

        return Center(
          child: Padding(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError
                      ? Icons.lock_outline
                      : Icons.error_outline,
                  size: AppDimensions.iconXL,
                  color: isPermissionError ? Colors.orange : Colors.red,
                ),
                SizedBox(height: AppDimensions.spaceS),
                Text(
                  isPermissionError
                      ? 'Nema dostupnih rezervacija'
                      : 'Greška pri učitavanju',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppDimensions.spaceXS),
                Text(
                  isPermissionError
                      ? 'Možda još nemaš nijednu rezervaciju'
                      : 'Pokušaj ponovo kasnije',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spaceM),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Osvježi listu nadolazećih rezervacija',
                      hint: 'Dvostruki dodir za ponovno učitavanje',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () => ref.invalidate(upcomingBookingsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Osvježi'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spaceXS),
                    Semantics(
                      label: 'Pretraži smještaje',
                      hint: 'Dvostruki dodir za pregled dostupnih smještaja',
                      button: true,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.search),
                        label: const Text('Pretraži smještaje'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
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
  const _PastBookingsTab();

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
                  size: AppDimensions.iconXL,
                  color: Colors.grey[400],
                ),
                SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Nema prošlih rezervacija',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppDimensions.spaceXS),
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
            padding: EdgeInsets.all(context.horizontalPadding),
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
      loading: () => ListView.builder(
        padding: EdgeInsets.all(context.horizontalPadding),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppDimensions.spaceS),
          child: const BookingCardSkeleton(),
        ),
      ),
      error: (error, stack) {
        // If error is about RLS/permissions, show friendly message
        final errorMessage = error.toString();
        final isPermissionError = errorMessage.contains('500') ||
            errorMessage.contains('policy') ||
            errorMessage.contains('permission');

        return Center(
          child: Padding(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError
                      ? Icons.lock_outline
                      : Icons.error_outline,
                  size: AppDimensions.iconXL,
                  color: isPermissionError ? Colors.orange : Colors.red,
                ),
                SizedBox(height: AppDimensions.spaceS),
                Text(
                  isPermissionError
                      ? 'Nema dostupnih rezervacija'
                      : 'Greška pri učitavanju',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppDimensions.spaceXS),
                Text(
                  isPermissionError
                      ? 'Možda još nemaš nijednu rezervaciju'
                      : 'Pokušaj ponovo kasnije',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spaceM),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Osvježi listu prošlih rezervacija',
                      hint: 'Dvostruki dodir za ponovno učitavanje',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () => ref.invalidate(pastBookingsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Osvježi'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spaceXS),
                    Semantics(
                      label: 'Pretraži smještaje',
                      hint: 'Dvostruki dodir za pregled dostupnih smještaja',
                      button: true,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.search),
                        label: const Text('Pretraži smještaje'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
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

class _CancelledBookingsTab extends ConsumerWidget {
  const _CancelledBookingsTab();

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
                  size: AppDimensions.iconXL,
                  color: Colors.grey[400],
                ),
                SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Nema otkazanih rezervacija',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppDimensions.spaceXS),
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
            padding: EdgeInsets.all(context.horizontalPadding),
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
      loading: () => ListView.builder(
        padding: EdgeInsets.all(context.horizontalPadding),
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppDimensions.spaceS),
          child: const BookingCardSkeleton(),
        ),
      ),
      error: (error, stack) {
        // If error is about RLS/permissions, show friendly message
        final errorMessage = error.toString();
        final isPermissionError = errorMessage.contains('500') ||
            errorMessage.contains('policy') ||
            errorMessage.contains('permission');

        return Center(
          child: Padding(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermissionError
                      ? Icons.lock_outline
                      : Icons.error_outline,
                  size: AppDimensions.iconXL,
                  color: isPermissionError ? Colors.orange : Colors.red,
                ),
                SizedBox(height: AppDimensions.spaceS),
                Text(
                  isPermissionError
                      ? 'Nema dostupnih rezervacija'
                      : 'Greška pri učitavanju',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: AppDimensions.spaceXS),
                Text(
                  isPermissionError
                      ? 'Možda još nemaš nijednu rezervaciju'
                      : 'Pokušaj ponovo kasnije',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spaceM),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Osvježi listu otkazanih rezervacija',
                      hint: 'Dvostruki dodir za ponovno učitavanje',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () => ref.invalidate(cancelledBookingsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Osvježi'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                    SizedBox(height: AppDimensions.spaceXS),
                    Semantics(
                      label: 'Pretraži smještaje',
                      hint: 'Dvostruki dodir za pregled dostupnih smještaja',
                      button: true,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.search),
                        label: const Text('Pretraži smještaje'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
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
