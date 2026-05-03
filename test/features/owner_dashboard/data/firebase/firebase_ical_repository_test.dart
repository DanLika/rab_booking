import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/features/owner_dashboard/data/firebase/firebase_ical_repository.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/ical_feed.dart';

void main() {
  group('FirebaseIcalRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseIcalRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseIcalRepository(firestore);
    });

    group('iCal Feeds CRUD', () {
      test('getOwnerIcalFeeds returns feeds from all properties', () async {
        final ownerId = 'owner1';
        final propertyId1 = 'prop1';
        final propertyId2 = 'prop2';

        // Create properties for the owner
        await firestore.collection('properties').doc(propertyId1).set({
          'owner_id': ownerId,
        });
        await firestore.collection('properties').doc(propertyId2).set({
          'owner_id': ownerId,
        });

        // Add a feed to property 1
        await firestore
            .collection('properties')
            .doc(propertyId1)
            .collection('ical_feeds')
            .doc('feed1')
            .set({
              'unit_id': 'unit1',
              'property_id': propertyId1,
              'platform': 'airbnb',
              'ical_url': 'https://example.com/airbnb.ics',
              'sync_interval_minutes': 60,
              'status': 'active',
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });

        // Add a feed to property 2
        await firestore
            .collection('properties')
            .doc(propertyId2)
            .collection('ical_feeds')
            .doc('feed2')
            .set({
              'unit_id': 'unit2',
              'property_id': propertyId2,
              'platform': 'booking_com',
              'ical_url': 'https://example.com/booking.ics',
              'sync_interval_minutes': 30,
              'status': 'paused',
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });

        final feeds = await repository.getOwnerIcalFeeds(ownerId);

        expect(feeds.length, 2);
        expect(
          feeds.any(
            (f) => f.id == 'feed1' && f.platform == IcalPlatform.airbnb,
          ),
          isTrue,
        );
        expect(
          feeds.any(
            (f) => f.id == 'feed2' && f.platform == IcalPlatform.bookingCom,
          ),
          isTrue,
        );
      });

      test(
        'getOwnerIcalFeeds returns empty list if owner has no properties',
        () async {
          final feeds = await repository.getOwnerIcalFeeds('unknown_owner');
          expect(feeds, isEmpty);
        },
      );

      test(
        'getUnitIcalFeeds returns feeds for specific unit via collectionGroup',
        () async {
          final unitId = 'target_unit';

          // Feed for target unit
          await firestore
              .collection('properties')
              .doc('prop1')
              .collection('ical_feeds')
              .doc('feed1')
              .set({
                'unit_id': unitId,
                'property_id': 'prop1',
                'platform': 'airbnb',
                'ical_url': 'https://example.com/airbnb.ics',
                'sync_interval_minutes': 60,
                'status': 'active',
                'created_at': Timestamp.now(),
                'updated_at': Timestamp.now(),
              });

          // Feed for a different unit
          await firestore
              .collection('properties')
              .doc('prop2')
              .collection('ical_feeds')
              .doc('feed2')
              .set({
                'unit_id': 'other_unit',
                'property_id': 'prop2',
                'platform': 'booking_com',
                'ical_url': 'https://example.com/booking.ics',
                'sync_interval_minutes': 30,
                'status': 'paused',
                'created_at': Timestamp.now(),
                'updated_at': Timestamp.now(),
              });

          final feeds = await repository.getUnitIcalFeeds(unitId);

          expect(feeds.length, 1);
          expect(feeds.first.id, 'feed1');
          expect(feeds.first.unitId, unitId);
        },
      );

      test(
        'createIcalFeed adds a new feed document and returns its ID',
        () async {
          final propertyId = 'prop1';
          final newFeed = IcalFeed(
            id: '', // Empty ID, should be generated
            unitId: 'unit1',
            propertyId: propertyId,
            platform: IcalPlatform.airbnb,
            icalUrl: 'https://example.com/new.ics',
            syncIntervalMinutes: 60,
            status: IcalStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final feedId = await repository.createIcalFeed(newFeed);

          expect(feedId, isNotEmpty);

          final doc = await firestore
              .collection('properties')
              .doc(propertyId)
              .collection('ical_feeds')
              .doc(feedId)
              .get();

          expect(doc.exists, isTrue);
          expect(doc.data()?['unit_id'], 'unit1');
          expect(doc.data()?['ical_url'], 'https://example.com/new.ics');
        },
      );

      test('updateIcalFeed updates an existing feed document', () async {
        final propertyId = 'prop1';
        final feedId = 'feedToUpdate';

        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .set({
              'unit_id': 'unit1',
              'property_id': propertyId,
              'platform': 'airbnb',
              'ical_url': 'https://example.com/old.ics',
              'sync_interval_minutes': 60,
              'status': 'active',
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });

        final updatedFeed = IcalFeed(
          id: feedId,
          unitId: 'unit1',
          propertyId: propertyId,
          platform: IcalPlatform.airbnb,
          icalUrl: 'https://example.com/new.ics',
          syncIntervalMinutes: 120, // changed
          status: IcalStatus.paused, // changed
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.updateIcalFeed(updatedFeed);

        final doc = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .get();

        expect(doc.data()?['ical_url'], 'https://example.com/new.ics');
        expect(doc.data()?['sync_interval_minutes'], 120);
        expect(doc.data()?['status'], 'paused');
      });

      test('deleteIcalFeed deletes the feed document', () async {
        final propertyId = 'prop1';
        final feedId = 'feedToDelete';

        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .set({
              'unit_id': 'unit1',
              'property_id': propertyId,
              'platform': 'airbnb',
              'ical_url': 'https://example.com/feed.ics',
            });

        await repository.deleteIcalFeed(feedId, propertyId);

        final doc = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .get();

        expect(doc.exists, isFalse);
      });

      test('updateFeedStatus updates the status and error message', () async {
        final propertyId = 'prop1';
        final feedId = 'feedToUpdate';

        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .set({
              'unit_id': 'unit1',
              'status': 'active',
              'updated_at': Timestamp.fromDate(DateTime(2020)),
            });

        await repository.updateFeedStatus(
          feedId,
          propertyId,
          IcalStatus.error,
          errorMessage: 'Connection failed',
        );

        final doc = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .get();

        expect(doc.data()?['status'], 'error');
        expect(doc.data()?['last_error'], 'Connection failed');
        expect(
          (doc.data()?['updated_at'] as Timestamp).toDate().year,
          DateTime.now().year,
        );
      });

      test('updateLastSync updates sync related fields correctly', () async {
        final propertyId = 'prop1';
        final feedId = 'feedToSync';

        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .set({
              'unit_id': 'unit1',
              'sync_count': 5,
              'status': 'error',
              'last_error': 'Some error',
            });

        await repository.updateLastSync(feedId, propertyId, 10);

        final doc = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc(feedId)
            .get();

        expect(doc.data()?['sync_count'], 6);
        expect(doc.data()?['event_count'], 10);
        expect(doc.data()?['status'], 'active');
        expect(doc.data()?['last_error'], isNull);
        expect(doc.data()?['last_synced'], isNotNull);
        expect(doc.data()?['updated_at'], isNotNull);
      });
    });

    group('iCal Events CRUD', () {
      test('getUnitIcalEvents returns sorted events for a unit', () async {
        final unitId = 'unit1';

        await firestore
            .collection('properties')
            .doc('prop1')
            .collection('ical_events')
            .doc('event1')
            .set({
              'unit_id': unitId,
              'start_date': Timestamp.fromDate(DateTime(2023, 1, 5)),
              'end_date': Timestamp.fromDate(DateTime(2023, 1, 10)),
            });

        await firestore
            .collection('properties')
            .doc('prop2')
            .collection('ical_events')
            .doc('event2')
            .set({
              'unit_id': unitId,
              'start_date': Timestamp.fromDate(DateTime(2023, 1, 1)),
              'end_date': Timestamp.fromDate(DateTime(2023, 1, 3)),
            });

        await firestore
            .collection('properties')
            .doc('prop1')
            .collection('ical_events')
            .doc('event3')
            .set({
              'unit_id': 'other_unit',
              'start_date': Timestamp.fromDate(DateTime(2023, 1, 1)),
            });

        final events = await repository.getUnitIcalEvents(unitId);

        expect(events.length, 2);
        // Should be sorted by start_date ascending
        expect(events[0].id, 'event2');
        expect(events[1].id, 'event1');
      });

      test(
        'getAllOwnerIcalEvents returns events from all properties',
        () async {
          final ownerId = 'owner1';

          await firestore.collection('properties').doc('prop1').set({
            'owner_id': ownerId,
          });
          await firestore.collection('properties').doc('prop2').set({
            'owner_id': ownerId,
          });

          await firestore
              .collection('properties')
              .doc('prop1')
              .collection('ical_events')
              .doc('event1')
              .set({
                'unit_id': 'unit1',
                'start_date': Timestamp.fromDate(DateTime(2023, 1, 1)),
              });

          await firestore
              .collection('properties')
              .doc('prop2')
              .collection('ical_events')
              .doc('event2')
              .set({
                'unit_id': 'unit2',
                'start_date': Timestamp.fromDate(DateTime(2023, 1, 5)),
              });

          final events = await repository.getAllOwnerIcalEvents(ownerId);

          expect(events.length, 2);
          // Sorted by start date descending
          expect(events[0].id, 'event2');
          expect(events[1].id, 'event1');
        },
      );

      test(
        'getUnitIcalEventsInRange returns events overlapping date range',
        () async {
          final unitId = 'unit1';
          final rangeStart = DateTime(2023, 1, 10);
          final rangeEnd = DateTime(2023, 1, 20);

          // Before range
          await firestore
              .collection('properties')
              .doc('prop1')
              .collection('ical_events')
              .add({
                'unit_id': unitId,
                'start_date': Timestamp.fromDate(DateTime(2023, 1, 1)),
                'end_date': Timestamp.fromDate(DateTime(2023, 1, 9)),
              });

          // Inside range
          await firestore
              .collection('properties')
              .doc('prop1')
              .collection('ical_events')
              .add({
                'unit_id': unitId,
                'start_date': Timestamp.fromDate(DateTime(2023, 1, 15)),
                'end_date': Timestamp.fromDate(DateTime(2023, 1, 18)),
              });

          // After range (does not match query constraints)
          await firestore
              .collection('properties')
              .doc('prop1')
              .collection('ical_events')
              .add({
                'unit_id': unitId,
                'start_date': Timestamp.fromDate(DateTime(2023, 1, 25)),
                'end_date': Timestamp.fromDate(DateTime(2023, 1, 28)),
              });

          final events = await repository.getUnitIcalEventsInRange(
            unitId: unitId,
            startDate: rangeStart,
            endDate: rangeEnd,
          );

          // Query looks for start_date >= rangeStart AND start_date < rangeEnd
          expect(events.length, 1);
          expect(events.first.startDate, DateTime(2023, 1, 15));
        },
      );

      test('createIcalEvent creates event and returns ID', () async {
        final propertyId = 'prop1';
        final event = IcalEvent(
          id: '',
          unitId: 'unit1',
          feedId: 'feed1',
          startDate: DateTime(2023, 1, 1),
          endDate: DateTime(2023, 1, 5),
          guestName: 'Guest',
          source: 'airbnb',
          externalId: 'ext1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final eventId = await repository.createIcalEvent(event, propertyId);

        expect(eventId, isNotEmpty);

        final doc = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_events')
            .doc(eventId)
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()?['unit_id'], 'unit1');
      });

      test('batchCreateIcalEvents creates multiple events', () async {
        final propertyId = 'prop1';
        final List<IcalEvent> events = [
          IcalEvent(
            id: '',
            unitId: 'unit1',
            feedId: 'feed1',
            startDate: DateTime(2023, 1, 1),
            endDate: DateTime(2023, 1, 5),
            guestName: 'Guest 1',
            source: 'booking_com',
            externalId: 'ext2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          IcalEvent(
            id: '',
            unitId: 'unit1',
            feedId: 'feed1',
            startDate: DateTime(2023, 1, 10),
            endDate: DateTime(2023, 1, 15),
            guestName: 'Guest 2',
            source: 'booking_com',
            externalId: 'ext3',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await repository.batchCreateIcalEvents(events, propertyId);

        final docs = await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_events')
            .get();

        expect(docs.docs.length, 2);
      });

      test(
        'deleteEventsForFeed deletes all events for specific feed',
        () async {
          final propertyId = 'prop1';

          await firestore
              .collection('properties')
              .doc(propertyId)
              .collection('ical_events')
              .add({'feed_id': 'feed1', 'unit_id': 'unit1'});

          await firestore
              .collection('properties')
              .doc(propertyId)
              .collection('ical_events')
              .add({'feed_id': 'feed1', 'unit_id': 'unit1'});

          await firestore
              .collection('properties')
              .doc(propertyId)
              .collection('ical_events')
              .add({'feed_id': 'feed2', 'unit_id': 'unit1'});

          await repository.deleteEventsForFeed('feed1', propertyId);

          final docs = await firestore
              .collection('properties')
              .doc(propertyId)
              .collection('ical_events')
              .get();

          expect(docs.docs.length, 1);
          expect(docs.docs.first.data()['feed_id'], 'feed2');
        },
      );

      test('checkIcalConflict returns true if events overlap', () async {
        final unitId = 'unit1';

        await firestore
            .collection('properties')
            .doc('prop1')
            .collection('ical_events')
            .add({
              'unit_id': unitId,
              'start_date': Timestamp.fromDate(DateTime(2023, 1, 5)),
              'end_date': Timestamp.fromDate(DateTime(2023, 1, 10)),
            });

        // Requesting 1-4 (No overlap)
        final conflict1 = await repository.checkIcalConflict(
          unitId: unitId,
          checkIn: DateTime(2023, 1, 1),
          checkOut: DateTime(2023, 1, 4),
        );
        expect(conflict1, isFalse);

        // Requesting 8-12 (Overlap)
        final conflict2 = await repository.checkIcalConflict(
          unitId: unitId,
          checkIn: DateTime(2023, 1, 8),
          checkOut: DateTime(2023, 1, 12),
        );
        expect(conflict2, isTrue);
      });
    });

    group('getIcalStatistics', () {
      test('returns correct statistics from owner feeds', () async {
        final ownerId = 'owner1';
        final propertyId = 'prop1';

        await firestore.collection('properties').doc(propertyId).set({
          'owner_id': ownerId,
        });

        // 1 Active feed
        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc('feed1')
            .set({
              'unit_id': 'unit1',
              'property_id': propertyId,
              'platform': 'airbnb',
              'ical_url': 'https://example.com/airbnb.ics',
              'sync_interval_minutes': 60,
              'status': 'active',
              'event_count': 5,
              'sync_count': 10,
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });

        // 1 Error feed
        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc('feed2')
            .set({
              'unit_id': 'unit1',
              'property_id': propertyId,
              'platform': 'booking_com',
              'ical_url': 'https://example.com/booking.ics',
              'sync_interval_minutes': 30,
              'status': 'error',
              'event_count': 2,
              'sync_count': 3,
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });

        // 1 Paused feed
        await firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .doc('feed3')
            .set({
              'unit_id': 'unit2',
              'property_id': propertyId,
              'platform': 'other',
              'ical_url': 'https://example.com/other.ics',
              'sync_interval_minutes': 120,
              'status': 'paused',
              'event_count': 0,
              'sync_count': 1,
              'created_at': Timestamp.now(),
              'updated_at': Timestamp.now(),
            });

        final stats = await repository.getIcalStatistics(ownerId);

        expect(stats['total_feeds'], 3);
        expect(stats['active_feeds'], 1);
        expect(stats['error_feeds'], 1);
        expect(stats['paused_feeds'], 1);
        expect(stats['total_events'], 7); // 5 + 2 + 0
        expect(stats['total_syncs'], 14); // 10 + 3 + 1
      });

      test(
        'returns empty-like stats when owner has no properties/feeds',
        () async {
          final stats = await repository.getIcalStatistics('unknown_owner');

          expect(stats['total_feeds'], 0);
          expect(stats['active_feeds'], 0);
          expect(stats['error_feeds'], 0);
          expect(stats['paused_feeds'], 0);
          expect(stats['total_events'], 0);
          expect(stats['total_syncs'], 0);
        },
      );
    });
  });
}
