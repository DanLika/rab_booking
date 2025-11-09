import 'package:flutter/material.dart';
import '../constants/enums.dart';

/// Centralized booking status utilities
/// Provides consistent colors and labels for booking statuses
class BookingStatusUtils {
  BookingStatusUtils._(); // Private constructor

  /// Get color for booking status
  static Color getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFFFA726); // Orange
      case BookingStatus.confirmed:
        return const Color(0xFF66BB6A); // Green
      case BookingStatus.checkedIn:
        return const Color(0xFF42A5F5); // Blue
      case BookingStatus.checkedOut:
        return const Color(0xFF9E9E9E); // Grey
      case BookingStatus.cancelled:
        return const Color(0xFFEF5350); // Red
      case BookingStatus.completed:
        return const Color(0xFF26A69A); // Teal
      case BookingStatus.inProgress:
        return const Color(0xFF9C27B0); // Purple
      case BookingStatus.blocked:
        return const Color(0xFF757575); // Grey
    }
  }

  /// Get background color for booking status (lighter shade)
  static Color getStatusBackgroundColor(BookingStatus status) {
    return getStatusColor(status).withOpacity(0.1);
  }

  /// Get text color for booking status (on colored background)
  static Color getStatusTextColor(BookingStatus status) {
    return getStatusColor(status);
  }

  /// Get status label in Croatian
  static String getStatusLabelHr(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Na čekanju';
      case BookingStatus.confirmed:
        return 'Potvrđeno';
      case BookingStatus.checkedIn:
        return 'Check-in';
      case BookingStatus.checkedOut:
        return 'Check-out';
      case BookingStatus.cancelled:
        return 'Otkazano';
      case BookingStatus.completed:
        return 'Završeno';
      case BookingStatus.inProgress:
        return 'U toku';
      case BookingStatus.blocked:
        return 'Blokirano';
    }
  }

  /// Get status label in English
  static String getStatusLabelEn(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.blocked:
        return 'Blocked';
    }
  }

  /// Get status icon
  static IconData getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.checkedIn:
        return Icons.login;
      case BookingStatus.checkedOut:
        return Icons.logout;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.inProgress:
        return Icons.pending;
      case BookingStatus.blocked:
        return Icons.block;
    }
  }

  /// Get payment status color
  static Color getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'plaćeno':
        return const Color(0xFF66BB6A); // Green
      case 'pending':
      case 'na čekanju':
        return const Color(0xFFFFA726); // Orange
      case 'failed':
      case 'neuspjelo':
        return const Color(0xFFEF5350); // Red
      case 'refunded':
      case 'vraćeno':
        return const Color(0xFF42A5F5); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get payment status label in Croatian
  static String getPaymentStatusLabelHr(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'Plaćeno';
      case 'pending':
        return 'Na čekanju';
      case 'failed':
        return 'Neuspjelo';
      case 'refunded':
        return 'Vraćeno';
      default:
        return paymentStatus;
    }
  }

  /// Check if status allows editing
  static bool canEditBooking(BookingStatus status) {
    return status != BookingStatus.cancelled &&
        status != BookingStatus.completed &&
        status != BookingStatus.checkedOut;
  }

  /// Check if status allows cancellation
  static bool canCancelBooking(BookingStatus status) {
    return status != BookingStatus.cancelled &&
        status != BookingStatus.completed &&
        status != BookingStatus.checkedOut;
  }

  /// Get next possible statuses for a booking
  static List<BookingStatus> getNextStatuses(BookingStatus currentStatus) {
    switch (currentStatus) {
      case BookingStatus.pending:
        return [
          BookingStatus.confirmed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.confirmed:
        return [
          BookingStatus.checkedIn,
          BookingStatus.cancelled,
        ];
      case BookingStatus.checkedIn:
        return [
          BookingStatus.checkedOut,
        ];
      case BookingStatus.checkedOut:
        return [
          BookingStatus.completed,
        ];
      case BookingStatus.cancelled:
      case BookingStatus.completed:
        return []; // Terminal states
      case BookingStatus.inProgress:
        return [
          BookingStatus.completed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.blocked:
        return []; // Terminal state
    }
  }
}
