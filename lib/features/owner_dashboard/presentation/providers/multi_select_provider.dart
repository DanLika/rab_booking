import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';

/// Multi-select mode state
class MultiSelectState {
  final bool isEnabled;
  final Set<String> selectedBookingIds;
  final List<BookingModel> selectedBookings;

  const MultiSelectState({
    this.isEnabled = false,
    this.selectedBookingIds = const {},
    this.selectedBookings = const [],
  });

  bool get hasSelection => selectedBookingIds.isNotEmpty;
  int get selectionCount => selectedBookingIds.length;

  bool isSelected(String bookingId) => selectedBookingIds.contains(bookingId);

  MultiSelectState copyWith({
    bool? isEnabled,
    Set<String>? selectedBookingIds,
    List<BookingModel>? selectedBookings,
  }) {
    return MultiSelectState(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedBookingIds: selectedBookingIds ?? this.selectedBookingIds,
      selectedBookings: selectedBookings ?? this.selectedBookings,
    );
  }
}

/// Multi-select state notifier
class MultiSelectNotifier extends StateNotifier<MultiSelectState> {
  MultiSelectNotifier() : super(const MultiSelectState());

  /// Enable multi-select mode
  void enableMultiSelect() {
    state = state.copyWith(isEnabled: true);
  }

  /// Disable multi-select mode and clear selection
  void disableMultiSelect() {
    state = const MultiSelectState();
  }

  /// Toggle selection for a booking
  void toggleSelection(BookingModel booking) {
    final newSelectedIds = Set<String>.from(state.selectedBookingIds);
    final newSelectedBookings = List<BookingModel>.from(state.selectedBookings);

    if (newSelectedIds.contains(booking.id)) {
      // Deselect
      newSelectedIds.remove(booking.id);
      newSelectedBookings.removeWhere((b) => b.id == booking.id);
    } else {
      // Select
      newSelectedIds.add(booking.id);
      newSelectedBookings.add(booking);
    }

    state = state.copyWith(
      selectedBookingIds: newSelectedIds,
      selectedBookings: newSelectedBookings,
    );
  }

  /// Select all bookings
  void selectAll(List<BookingModel> bookings) {
    state = state.copyWith(
      selectedBookingIds: bookings.map((b) => b.id).toSet(),
      selectedBookings: bookings,
    );
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(
      selectedBookingIds: {},
      selectedBookings: [],
    );
  }

  /// Select bookings by predicate
  void selectWhere(List<BookingModel> allBookings, bool Function(BookingModel) predicate) {
    final selected = allBookings.where(predicate).toList();
    state = state.copyWith(
      selectedBookingIds: selected.map((b) => b.id).toSet(),
      selectedBookings: selected,
    );
  }
}

/// Multi-select provider
final multiSelectProvider =
    StateNotifierProvider<MultiSelectNotifier, MultiSelectState>((ref) {
  return MultiSelectNotifier();
});
