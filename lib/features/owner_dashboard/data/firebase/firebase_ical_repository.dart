import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/ical_feed.dart';
import '../../../../core/services/logging_service.dart';

/// Repository for managing iCal feeds and events
///
/// Structure:
/// - ical_feeds: properties/{propertyId}/ical_feeds/{feedId}
/// - ical_events: properties/{propertyId}/ical_events/{eventId}
class FirebaseIcalRepository {
  final FirebaseFirestore _firestore;

  FirebaseIcalRepository(this._firestore);

  // ============================================
  // iCal Feeds CRUD
  // ============================================

  /// Get all iCal feeds for owner's properties
  /// Uses collectionGroup query since feeds are now subcollections
  Future<List<IcalFeed>> getOwnerIcalFeeds(String ownerId) async {
    try {
      // First, get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) return [];

      // Query feeds from each property's subcollection
      final List<IcalFeed> allFeeds = [];
      for (final propertyId in propertyIds) {
        final feedsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_feeds')
            .get();
        allFeeds.addAll(feedsSnapshot.docs.map(IcalFeed.fromFirestore));
      }

      return allFeeds;
    } catch (e, stack) {
      unawaited(LoggingService.logError('Error getting owner feeds', e, stack));
      return [];
    }
  }

  /// Get iCal feeds for specific unit
  /// Uses collectionGroup query since feeds are subcollections
  Future<List<IcalFeed>> getUnitIcalFeeds(String unitId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('ical_feeds')
          .where('unit_id', isEqualTo: unitId)
          .get();

      return snapshot.docs.map(IcalFeed.fromFirestore).toList();
    } catch (e, stack) {
      unawaited(LoggingService.logError('Error getting unit feeds', e, stack));
      return [];
    }
  }

  /// Watch all iCal feeds for owner's properties (real-time)
  Stream<List<IcalFeed>> watchOwnerIcalFeeds(String ownerId) {
    return _firestore
        .collection('properties')
        .where('owner_id', isEqualTo: ownerId)
        .snapshots()
        .asyncMap((propertiesSnapshot) async {
          final propertyIds = propertiesSnapshot.docs
              .map((doc) => doc.id)
              .toList();

          if (propertyIds.isEmpty) return <IcalFeed>[];

          // Query feeds from each property's subcollection
          final List<IcalFeed> allFeeds = [];
          for (final propertyId in propertyIds) {
            final feedsSnapshot = await _firestore
                .collection('properties')
                .doc(propertyId)
                .collection('ical_feeds')
                .get();
            allFeeds.addAll(feedsSnapshot.docs.map(IcalFeed.fromFirestore));
          }

          return allFeeds;
        });
  }

  /// Create new iCal feed
  /// Path: properties/{propertyId}/ical_feeds/{feedId}
  Future<String> createIcalFeed(IcalFeed feed) async {
    try {
      final docRef = await _firestore
          .collection('properties')
          .doc(feed.propertyId)
          .collection('ical_feeds')
          .add(
            feed
                .copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now())
                .toFirestore(),
          );

      // Security: Log new iCal source being trusted
      LoggingService.log(
        'SECURITY: New iCal feed created - feedId: ${docRef.id}, '
        'platform: ${feed.platform.name}, unitId: ${feed.unitId}',
        tag: 'ICAL_SECURITY',
      );
      return docRef.id;
    } catch (e, stack) {
      unawaited(LoggingService.logError('Error creating iCal feed', e, stack));
      rethrow;
    }
  }

  /// Update iCal feed
  /// Path: properties/{propertyId}/ical_feeds/{feedId}
  Future<void> updateIcalFeed(IcalFeed feed) async {
    try {
      await _firestore
          .collection('properties')
          .doc(feed.propertyId)
          .collection('ical_feeds')
          .doc(feed.id)
          .update(feed.copyWith(updatedAt: DateTime.now()).toFirestore());

      // Security: Log iCal feed modification
      LoggingService.log(
        'SECURITY: iCal feed updated - feedId: ${feed.id}, '
        'platform: ${feed.platform.name}, unitId: ${feed.unitId}',
        tag: 'ICAL_SECURITY',
      );
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'Error updating iCal feed: ${feed.id}',
          e,
          stack,
        ),
      );
      rethrow;
    }
  }

  /// Delete iCal feed and its events
  /// Path: properties/{propertyId}/ical_feeds/{feedId}
  Future<void> deleteIcalFeed(String feedId, String propertyId) async {
    LoggingService.log(
      'Deleting feed: $feedId from property: $propertyId',
      tag: 'IcalRepository',
    );

    try {
      // Query path: properties/{propertyId}/ical_events where feed_id == feedId
      final eventsQuery = _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_events')
          .where('feed_id', isEqualTo: feedId);

      LoggingService.log(
        'Querying events at: properties/$propertyId/ical_events where feed_id == $feedId',
        tag: 'IcalRepository',
      );

      final eventsSnapshot = await eventsQuery.get();

      LoggingService.log(
        'Found ${eventsSnapshot.docs.length} events to delete',
        tag: 'IcalRepository',
      );

      // Log each event being deleted for debugging
      for (final doc in eventsSnapshot.docs) {
        LoggingService.log(
          'Deleting event: ${doc.id} (feed_id: ${doc.data()['feed_id']})',
          tag: 'IcalRepository',
        );
      }

      // Use batch delete (Firestore batch limit is 500)
      const batchSize = 500;
      int deletedCount = 0;
      for (int i = 0; i < eventsSnapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final batchDocs = eventsSnapshot.docs.skip(i).take(batchSize);

        for (final doc in batchDocs) {
          batch.delete(doc.reference);
          deletedCount++;
        }

        await batch.commit();
        LoggingService.log(
          'Batch committed: $deletedCount events deleted so far',
          tag: 'IcalRepository',
        );
      }

      // Delete the feed from subcollection
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_feeds')
          .doc(feedId)
          .delete();

      // Security: Log iCal feed deletion
      LoggingService.log(
        'SECURITY: iCal feed deleted - feedId: $feedId, '
        'propertyId: $propertyId, eventsRemoved: $deletedCount',
        tag: 'ICAL_SECURITY',
      );
    } catch (e, stackTrace) {
      unawaited(
        LoggingService.logError(
          'Error deleting iCal feed: $feedId',
          e,
          stackTrace,
        ),
      );
      rethrow;
    }
  }

  /// Update feed status (active/error/paused)
  /// Path: properties/{propertyId}/ical_feeds/{feedId}
  Future<void> updateFeedStatus(
    String feedId,
    String propertyId,
    IcalStatus status, {
    String? errorMessage,
  }) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_feeds')
          .doc(feedId)
          .update({
            'status': status.toFirestoreValue(),
            'last_error': errorMessage,
            'updated_at': Timestamp.now(),
          });

      LoggingService.log(
        'Feed status updated: $feedId -> $status',
        tag: 'IcalRepository',
      );
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'Error updating feed status: $feedId',
          e,
          stack,
        ),
      );
      rethrow;
    }
  }

  /// Update last sync timestamp
  /// Path: properties/{propertyId}/ical_feeds/{feedId}
  Future<void> updateLastSync(
    String feedId,
    String propertyId,
    int eventCount,
  ) async {
    try {
      final feedDoc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_feeds')
          .doc(feedId)
          .get();
      final currentSyncCount = (feedDoc.data()?['sync_count'] ?? 0) as int;

      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_feeds')
          .doc(feedId)
          .update({
            'last_synced': Timestamp.now(),
            'sync_count': currentSyncCount + 1,
            'event_count': eventCount,
            'status': 'active',
            'last_error': null,
            'updated_at': Timestamp.now(),
          });

      LoggingService.log(
        'Last sync updated for feed: $feedId',
        tag: 'IcalRepository',
      );
    } catch (e, stack) {
      unawaited(
        LoggingService.logError('Error updating last sync: $feedId', e, stack),
      );
      rethrow;
    }
  }

  // ============================================
  // iCal Events CRUD
  // ============================================

  /// Get all iCal events for a unit
  Future<List<IcalEvent>> getUnitIcalEvents(String unitId) async {
    try {
      // NEW STRUCTURE: Use collection group query since we don't know propertyId
      final snapshot = await _firestore
          .collectionGroup('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .orderBy('start_date', descending: false)
          .get();

      return snapshot.docs.map(IcalEvent.fromFirestore).toList();
    } catch (e, stack) {
      unawaited(LoggingService.logError('Error getting unit events', e, stack));
      return [];
    }
  }

  /// Get ALL iCal events across all owner's properties
  /// Used on the Bookings page when "Imported" tab is selected
  Future<List<IcalEvent>> getAllOwnerIcalEvents(String ownerId) async {
    try {
      // First, get all owner's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) return [];

      // Query events from each property's subcollection
      final List<IcalEvent> allEvents = [];
      for (final propertyId in propertyIds) {
        final eventsSnapshot = await _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_events')
            .orderBy('start_date', descending: true)
            .get();
        allEvents.addAll(eventsSnapshot.docs.map(IcalEvent.fromFirestore));
      }

      // Sort by start date descending (most recent first)
      allEvents.sort((a, b) => b.startDate.compareTo(a.startDate));

      return allEvents;
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'Error getting all owner iCal events',
          e,
          stack,
        ),
      );
      return [];
    }
  }

  /// Get iCal events for a unit within date range
  Future<List<IcalEvent>> getUnitIcalEventsInRange({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // NEW STRUCTURE: Use collection group query since we don't know propertyId
      final snapshot = await _firestore
          .collectionGroup('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .where('start_date', isGreaterThanOrEqualTo: startDate)
          .where('start_date', isLessThan: endDate)
          .get();

      return snapshot.docs.map(IcalEvent.fromFirestore).toList();
    } catch (e, stack) {
      unawaited(
        LoggingService.logError('Error getting events in range', e, stack),
      );
      return [];
    }
  }

  /// Watch iCal events for a unit (real-time)
  Stream<List<IcalEvent>> watchUnitIcalEvents(String unitId) {
    // NEW STRUCTURE: Use collection group query since we don't know propertyId
    return _firestore
        .collectionGroup('ical_events')
        .where('unit_id', isEqualTo: unitId)
        .orderBy('start_date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(IcalEvent.fromFirestore).toList();
        });
  }

  /// Create iCal event
  /// Requires propertyId since feeds are now subcollections
  Future<String> createIcalEvent(IcalEvent event, String propertyId) async {
    try {
      // Write to subcollection structure
      final docRef = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_events')
          .add(
            event
                .copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now())
                .toFirestore(),
          );

      LoggingService.log('Event created: ${docRef.id}', tag: 'IcalRepository');
      return docRef.id;
    } catch (e, stack) {
      unawaited(LoggingService.logError('Error creating event', e, stack));
      rethrow;
    }
  }

  /// Batch create iCal events (for sync)
  /// Requires propertyId since feeds are now subcollections
  Future<void> batchCreateIcalEvents(
    List<IcalEvent> events,
    String propertyId,
  ) async {
    try {
      if (events.isEmpty) return;

      // Write to subcollection structure
      final batch = _firestore.batch();

      for (final event in events) {
        final docRef = _firestore
            .collection('properties')
            .doc(propertyId)
            .collection('ical_events')
            .doc();
        batch.set(docRef, event.toFirestore());
      }

      await batch.commit();
      LoggingService.log(
        'Batch created ${events.length} events in property $propertyId',
        tag: 'IcalRepository',
      );
    } catch (e, stack) {
      unawaited(
        LoggingService.logError('Error batch creating events', e, stack),
      );
      rethrow;
    }
  }

  /// Delete all events for a feed (before re-syncing)
  /// Requires propertyId since feeds are now subcollections
  Future<void> deleteEventsForFeed(String feedId, String propertyId) async {
    try {
      // Query events from subcollection structure
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('ical_events')
          .where('feed_id', isEqualTo: feedId)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      LoggingService.log(
        'Deleted ${snapshot.docs.length} events for feed: $feedId',
        tag: 'IcalRepository',
      );
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'Error deleting events for feed: $feedId',
          e,
          stack,
        ),
      );
      rethrow;
    }
  }

  /// Check if date range conflicts with iCal events
  Future<bool> checkIcalConflict({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // NEW STRUCTURE: Use collection group query since we don't know propertyId
      final snapshot = await _firestore
          .collectionGroup('ical_events')
          .where('unit_id', isEqualTo: unitId)
          .where('start_date', isLessThan: checkOut)
          .get();

      // Filter events that actually overlap
      final conflictingEvents = snapshot.docs
          .map(IcalEvent.fromFirestore)
          .where((event) => event.overlaps(checkIn, checkOut))
          .toList();

      return conflictingEvents.isNotEmpty;
    } catch (e, stack) {
      unawaited(
        LoggingService.logError('Error checking iCal conflict', e, stack),
      );
      return false;
    }
  }

  /// Get statistics for owner's iCal syncs
  Future<Map<String, dynamic>> getIcalStatistics(String ownerId) async {
    try {
      final feeds = await getOwnerIcalFeeds(ownerId);

      final totalFeeds = feeds.length;
      final activeFeeds = feeds.where((f) => f.isActive).length;
      final errorFeeds = feeds.where((f) => f.hasError).length;
      final totalEvents = feeds.fold(0, (acc, feed) => acc + feed.eventCount);
      final totalSyncs = feeds.fold(0, (acc, feed) => acc + feed.syncCount);

      return {
        'total_feeds': totalFeeds,
        'active_feeds': activeFeeds,
        'error_feeds': errorFeeds,
        'paused_feeds': totalFeeds - activeFeeds - errorFeeds,
        'total_events': totalEvents,
        'total_syncs': totalSyncs,
      };
    } catch (e, stack) {
      unawaited(
        LoggingService.logError('Error getting iCal statistics', e, stack),
      );
      return {};
    }
  }
}
