// Deterministic mock data for the golden net (P6).
//
// Every value here is fixed (no `DateTime.now()`, no randomness) so the same
// pixels render on every run. Adapted from the existing overflow harnesses
// (`dashboard_overview_responsive_test`, `owner_booking_detail_layout_test`,
// `ai_assistant_premium_test`) — centralised so a model-shape change updates one
// place. Mirrors the handoff sample (€3.840 / 14 / 78% / 4 arrivals).

import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/ai_chat.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/unified_dashboard_data.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/shared/models/property_model.dart';
import 'package:bookbed/shared/models/unit_model.dart';

/// Fixed "last 30 days" range for the Pregled panel.
DateRangeFilter dashboardRange() => DateRangeFilter(
  startDate: DateTime(2026, 5),
  endDate: DateTime(2026, 5, 30),
  preset: 'last30',
);

/// Pregled / Dashboard Overview fixture — handoff sample numbers + a rising
/// 14-point revenue & booking history so the chart and sparkline render.
UnifiedDashboardData dashboardFixture() {
  final DateTime base = DateTime(2026, 5);
  const List<double> amounts = <double>[
    600,
    950,
    800,
    1300,
    1500,
    1200,
    1750,
    1600,
    2100,
    2300,
    2600,
    3000,
    3600,
    3840,
  ];
  final List<RevenueDataPoint> revenueHistory = <RevenueDataPoint>[
    for (int i = 0; i < amounts.length; i++)
      RevenueDataPoint(
        date: base.add(Duration(days: i * 2)),
        amount: amounts[i],
        label: '${1 + i * 2}.',
      ),
  ];
  final List<BookingDataPoint> bookingHistory = <BookingDataPoint>[
    for (int i = 0; i < amounts.length; i++)
      BookingDataPoint(
        date: base.add(Duration(days: i * 2)),
        count: 6 + i,
        label: '${1 + i * 2}.',
      ),
  ];
  return UnifiedDashboardData(
    revenue: 3840,
    bookings: 14,
    upcomingCheckIns: 4,
    distinctGuests: 9,
    occupancyRate: 78,
    revenueBySource: const <String, double>{
      'direct': 2640,
      'booking_com': 840,
      'airbnb': 360,
    },
    depositsCollected: 768,
    depositsOutstanding: 3072,
    upcomingArrivals: <UpcomingArrival>[
      UpcomingArrival(
        bookingId: '1',
        guestName: 'Marko Horvat',
        propertyName: 'Vila Marina',
        unitName: 'Studio 4',
        checkIn: DateTime(2026, 7, 8),
        nights: 3,
        status: 'pending',
      ),
      UpcomingArrival(
        bookingId: '2',
        guestName: 'Sandra Kovač',
        propertyName: 'Stan Lavanda',
        unitName: 'Apartman A',
        checkIn: DateTime(2026, 7, 12),
        nights: 3,
        status: 'confirmed',
      ),
      UpcomingArrival(
        bookingId: '3',
        guestName: 'Eva Novak',
        propertyName: 'Vila Marina',
        unitName: 'Premium',
        checkIn: DateTime(2026, 7, 15),
        nights: 5,
        status: 'confirmed',
      ),
      UpcomingArrival(
        bookingId: '4',
        guestName: 'Luka Babić',
        propertyName: 'Stan Lavanda',
        unitName: 'Studio B',
        checkIn: DateTime(2026, 7, 19),
        nights: 2,
        status: 'confirmed',
      ),
    ],
    revenueHistory: revenueHistory,
    bookingHistory: bookingHistory,
  );
}

/// Owner booking-detail fixture. Defaults to a pending booking 5 days out.
OwnerBooking ownerBookingFixture({
  BookingStatus status = BookingStatus.pending,
  int checkInOffsetDays = 5,
  int checkOutOffsetDays = 8,
  String guest = 'Marko Horvat',
  String property = 'Vila Marina',
  String unit = 'Studio 4',
  String? notes = 'Stižemo oko 21:00, molim ostavite ključ.',
}) {
  final DateTime now = DateTime(2026, 7, 8, 14);
  return OwnerBooking(
    booking: BookingModel(
      id: 'bd-test',
      unitId: 'u1',
      checkIn: now.add(Duration(days: checkInOffsetDays)),
      checkOut: now.add(Duration(days: checkOutOffsetDays)),
      status: status,
      createdAt: now.subtract(const Duration(days: 2)),
      totalPrice: 360,
      paidAmount: 72,
      notes: notes,
    ),
    property: PropertyModel(
      id: 'p1',
      name: property,
      description: 'desc',
      location: 'Rab',
      createdAt: now,
    ),
    unit: UnitModel(
      id: 'u1',
      propertyId: 'p1',
      name: unit,
      pricePerNight: 120,
      maxGuests: 2,
      createdAt: now,
    ),
    guestName: guest,
    guestEmail: 'marko.horvat@gmail.com',
    guestPhone: '+385 91 234 5678',
  );
}

/// A short user + assistant exchange for the AI message bubbles.
List<AiChatMessage> aiChatFixture() => <AiChatMessage>[
  AiChatMessage(
    role: 'user',
    content: 'Kako blokirati datume za održavanje u srpnju?',
    timestamp: DateTime(2026, 6, 16, 10, 42),
  ),
  AiChatMessage(
    role: 'assistant',
    content:
        '**Kratko:** otvorite Mjesečni kalendar.\n\n'
        'Odaberite raspon dana i označite ih kao nedostupne — '
        'tako gosti ne mogu rezervirati te termine.\n\n'
        '- otvorite kalendar\n- odaberite datume\n- spremite',
    timestamp: DateTime(2026, 6, 16, 10, 43),
  ),
];
