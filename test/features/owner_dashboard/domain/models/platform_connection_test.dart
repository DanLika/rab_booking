import 'package:bookbed/features/owner_dashboard/domain/models/platform_connection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformType', () {
    test('displayName returns correct string', () {
      expect(PlatformType.bookingCom.displayName, 'Booking.com');
      expect(PlatformType.airbnb.displayName, 'Airbnb');
    });

    test('fromString parses correctly', () {
      expect(PlatformType.fromString('booking_com'), PlatformType.bookingCom);
      expect(PlatformType.fromString('airbnb'), PlatformType.airbnb);
      expect(PlatformType.fromString('unknown'), PlatformType.bookingCom);
      expect(PlatformType.fromString(null), PlatformType.bookingCom);
    });

    test('toFirestoreValue returns correct string', () {
      expect(PlatformType.bookingCom.toFirestoreValue(), 'booking_com');
      expect(PlatformType.airbnb.toFirestoreValue(), 'airbnb');
    });
  });

  group('ConnectionStatus', () {
    test('colorName returns correct string', () {
      expect(ConnectionStatus.active.colorName, 'green');
      expect(ConnectionStatus.expired.colorName, 'orange');
      expect(ConnectionStatus.error.colorName, 'red');
      expect(ConnectionStatus.pending.colorName, 'blue');
    });

    test('fromString parses correctly', () {
      expect(ConnectionStatus.fromString('active'), ConnectionStatus.active);
      expect(ConnectionStatus.fromString('expired'), ConnectionStatus.expired);
      expect(ConnectionStatus.fromString('error'), ConnectionStatus.error);
      expect(ConnectionStatus.fromString('pending'), ConnectionStatus.pending);
      expect(ConnectionStatus.fromString('unknown'), ConnectionStatus.pending);
      expect(ConnectionStatus.fromString(null), ConnectionStatus.pending);
    });

    test('toFirestoreValue returns correct string', () {
      expect(ConnectionStatus.active.toFirestoreValue(), 'active');
      expect(ConnectionStatus.expired.toFirestoreValue(), 'expired');
      expect(ConnectionStatus.error.toFirestoreValue(), 'error');
      expect(ConnectionStatus.pending.toFirestoreValue(), 'pending');
    });
  });

  group('PlatformConnection', () {
    final now = DateTime(2024, 1, 1, 12, 0, 0);

    test('fromFirestore creates correct object', () async {
      final firestore = FakeFirebaseFirestore();

      final docRef = firestore.collection('platform_connections').doc('conn_1');
      await docRef.set({
        'owner_id': 'owner_1',
        'platform': 'booking_com',
        'unit_id': 'unit_1',
        'external_property_id': 'ext_prop_1',
        'external_unit_id': 'ext_unit_1',
        'expires_at': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'status': 'active',
        'last_error': 'Some error',
        'last_synced_at': Timestamp.fromDate(now),
        'last_sync_event_count': 5,
        'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'updated_at': Timestamp.fromDate(now),
      });

      final snapshot = await docRef.get();
      final connection = PlatformConnection.fromFirestore(snapshot);

      expect(connection.id, 'conn_1');
      expect(connection.ownerId, 'owner_1');
      expect(connection.platform, PlatformType.bookingCom);
      expect(connection.unitId, 'unit_1');
      expect(connection.externalPropertyId, 'ext_prop_1');
      expect(connection.externalUnitId, 'ext_unit_1');
      expect(connection.expiresAt, now.add(const Duration(days: 30)));
      expect(connection.status, ConnectionStatus.active);
      expect(connection.lastError, 'Some error');
      expect(connection.lastSyncedAt, now);
      expect(connection.lastSyncEventCount, 5);
      expect(connection.createdAt, now.subtract(const Duration(days: 1)));
      expect(connection.updatedAt, now);
    });

    test('toFirestore creates correct map', () {
      final connection = PlatformConnection(
        id: 'conn_1', // not included in toFirestore
        ownerId: 'owner_1',
        platform: PlatformType.airbnb,
        unitId: 'unit_1',
        externalPropertyId: 'ext_prop_1',
        externalUnitId: 'ext_unit_1',
        expiresAt: now.add(const Duration(days: 30)),
        status: ConnectionStatus.pending,
        lastError: null,
        lastSyncedAt: null,
        lastSyncEventCount: null,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );

      final map = connection.toFirestore();

      expect(map['owner_id'], 'owner_1');
      expect(map['platform'], 'airbnb');
      expect(map['unit_id'], 'unit_1');
      expect(map['external_property_id'], 'ext_prop_1');
      expect(map['external_unit_id'], 'ext_unit_1');
      expect(
        map['expires_at'],
        Timestamp.fromDate(now.add(const Duration(days: 30))),
      );
      expect(map['status'], 'pending');
      expect(map['last_error'], null);
      expect(map['last_synced_at'], null);
      expect(map['last_sync_event_count'], null);
      expect(
        map['created_at'],
        Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      );
      expect(map['updated_at'], Timestamp.fromDate(now));
    });

    test('isActive returns true only when status is active', () {
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: now,
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.active,
        ).isActive,
        isTrue,
      );
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: now,
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.pending,
        ).isActive,
        isFalse,
      );
    });

    test('isExpired returns true when status is expired or date is past', () {
      // Future date, but status expired
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.expired,
        ).isExpired,
        isTrue,
      );

      // Past date, status active
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.active,
        ).isExpired,
        isTrue,
      );

      // Future date, status active
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.active,
        ).isExpired,
        isFalse,
      );
    });

    test('hasError returns true only when status is error', () {
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: now,
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.error,
        ).hasError,
        isTrue,
      );
      expect(
        PlatformConnection(
          id: '1',
          ownerId: '1',
          platform: PlatformType.airbnb,
          unitId: '1',
          externalPropertyId: '1',
          externalUnitId: '1',
          expiresAt: now,
          createdAt: now,
          updatedAt: now,
          status: ConnectionStatus.active,
        ).hasError,
        isFalse,
      );
    });

    test('getTimeSinceLastSync formats correctly', () {
      final baseConnection = PlatformConnection(
        id: '1',
        ownerId: '1',
        platform: PlatformType.airbnb,
        unitId: '1',
        externalPropertyId: '1',
        externalUnitId: '1',
        expiresAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // Null lastSyncedAt
      expect(
        baseConnection.copyWith(lastSyncedAt: null).getTimeSinceLastSync(),
        'Never',
      );

      // Just now (< 1 min)
      expect(
        baseConnection
            .copyWith(
              lastSyncedAt: DateTime.now().subtract(
                const Duration(seconds: 30),
              ),
            )
            .getTimeSinceLastSync(),
        'Just now',
      );

      // X min ago (< 60 mins)
      expect(
        baseConnection
            .copyWith(
              lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            )
            .getTimeSinceLastSync(),
        '5 min ago',
      );

      // X h ago (< 24 hours)
      expect(
        baseConnection
            .copyWith(
              lastSyncedAt: DateTime.now().subtract(const Duration(hours: 3)),
            )
            .getTimeSinceLastSync(),
        '3 h ago',
      );

      // X days ago (>= 24 hours)
      expect(
        baseConnection
            .copyWith(
              lastSyncedAt: DateTime.now().subtract(
                const Duration(days: 2, hours: 2),
              ),
            )
            .getTimeSinceLastSync(),
        '2 days ago',
      );
    });
  });
}
