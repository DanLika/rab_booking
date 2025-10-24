import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_state_provider.dart';
import '../../../../core/utils/adaptive_spacing.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../domain/models/property_unit.dart';

/// Authentication-aware booking button
///
/// Shows "Book Now" button that:
/// - Navigates to booking flow if user is authenticated
/// - Shows toast notification with login link if not authenticated
class BookingFAB extends ConsumerWidget {
  const BookingFAB({
    required this.unit,
    this.price,
    this.isFloating = true,
    super.key,
  });

  final PropertyUnit unit;
  final double? price;
  final bool isFloating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (isFloating) {
      return _buildFloatingButton(context, isAuthenticated);
    } else {
      return _buildStickyButton(context, isAuthenticated);
    }
  }

  Widget _buildFloatingButton(BuildContext context, bool isAuthenticated) {
    return Positioned(
      bottom: context.spacing.large,
      left: context.spacing.large,
      right: context.spacing.large,
      child: SafeArea(
        child: _buildButton(context, isAuthenticated),
      ),
    );
  }

  Widget _buildStickyButton(BuildContext context, bool isAuthenticated) {
    return Container(
      padding: EdgeInsets.all(context.spacing.medium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildButton(context, isAuthenticated),
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isAuthenticated) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _handleBooking(context, isAuthenticated),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.large,
              vertical: context.spacing.medium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price section
                if (price != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${price!.toStringAsFixed(0)}',
                        style: context.typography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'per night',
                        style: context.typography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                // Book button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book Now',
                      style: context.typography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.spacing.small),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBooking(BuildContext context, bool isAuthenticated) {
    if (isAuthenticated) {
      // User is logged in - navigate to booking flow
      context.push('/booking/${unit.id}');
    } else {
      // User is NOT logged in - show toast with login link
      _showLoginToast(context);
    }
  }

  void _showLoginToast(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            SizedBox(width: context.spacing.small),
            Expanded(
              child: Text(
                'Niste ulogovani',
                style: context.typography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Idi na Login',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            context.push('/auth/login');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(context.spacing.medium),
      ),
    );
  }
}

/// Sticky bottom bar variant (alternative to FAB)
///
/// Use this when you want a persistent booking bar at the bottom
class BookingStickyBar extends ConsumerWidget {
  const BookingStickyBar({
    required this.unit,
    this.price,
    this.onBookPressed,
    super.key,
  });

  final PropertyUnit unit;
  final double? price;
  final VoidCallback? onBookPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    return Container(
      padding: EdgeInsets.all(context.spacing.medium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price info
            if (price != null)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${price!.toStringAsFixed(0)}',
                          style: context.typography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: context.spacing.extraSmall),
                        Text(
                          '/ night',
                          style: context.typography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Plus taxes and fees',
                      style: context.typography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(width: context.spacing.medium),

            // Book button
            Expanded(
              flex: 3,
              child: PrimaryButton(
                text: 'Reserve',
                onPressed: () {
                  if (isAuthenticated) {
                    onBookPressed?.call();
                    context.push('/booking/${unit.id}');
                  } else {
                    _showLoginToast(context);
                  }
                },
                icon: Icons.event_available,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginToast(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            SizedBox(width: context.spacing.small),
            Expanded(
              child: Text(
                'Morate biti ulogovani da biste rezervisali',
                style: context.typography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Login',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            context.push('/auth/login');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(context.spacing.medium),
      ),
    );
  }
}
