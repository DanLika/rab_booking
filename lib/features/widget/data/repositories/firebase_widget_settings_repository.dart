import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../core/services/logging_service.dart';

/// Repository for managing widget settings in Firestore
/// Path: properties/{propertyId}/widget_settings/{unitId}
class FirebaseWidgetSettingsRepository {
  final FirebaseFirestore _firestore;

  /// Firestore collection names
  static const String _propertiesCollection = 'properties';
  static const String _widgetSettingsSubcollection = 'widget_settings';

  /// Log tag for this repository
  static const String _logTag = 'WidgetSettingsRepository';

  /// Maximum operations per Firestore batch
  static const int _maxBatchSize = 500;

  FirebaseWidgetSettingsRepository(this._firestore);

  /// Get document reference for widget settings
  DocumentReference<Map<String, dynamic>> _settingsDocRef(
    String propertyId,
    String unitId,
  ) => _firestore
      .collection(_propertiesCollection)
      .doc(propertyId)
      .collection(_widgetSettingsSubcollection)
      .doc(unitId);

  /// Get collection reference for all widget settings in a property
  CollectionReference<Map<String, dynamic>> _settingsCollectionRef(
    String propertyId,
  ) => _firestore
      .collection(_propertiesCollection)
      .doc(propertyId)
      .collection(_widgetSettingsSubcollection);

  /// Get widget settings for a specific unit
  Future<WidgetSettings?> getWidgetSettings({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      final doc = await _settingsDocRef(propertyId, unitId).get();

      if (!doc.exists) return null;

      return WidgetSettings.fromFirestore(doc);
    } catch (e) {
      LoggingService.log('Error getting settings: $e', tag: _logTag);
      return null;
    }
  }

  /// Watch widget settings for real-time updates
  Stream<WidgetSettings?> watchWidgetSettings({
    required String propertyId,
    required String unitId,
  }) {
    return _settingsDocRef(propertyId, unitId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          try {
            return WidgetSettings.fromFirestore(doc);
          } catch (e) {
            LoggingService.logError('Error parsing widget settings', e);
            return null;
          }
        })
        .onErrorReturnWith((error, stackTrace) {
          LoggingService.logError(
            'Error in widget settings stream',
            error,
            stackTrace,
          );
          return null;
        });
  }

  /// Create default widget settings for a new unit
  Future<void> createDefaultSettings({
    required String propertyId,
    required String unitId,
    required String ownerId,
    String? ownerEmail,
    String? ownerPhone,
    List<int>? weekendDays,
  }) async {
    try {
      final settings = WidgetSettings(
        id: unitId,
        propertyId: propertyId,
        ownerId: ownerId, // Required for Firestore security rules
        widgetMode:
            WidgetMode.calendarOnly, // Default: show availability + contact
        contactOptions: ContactOptions(
          emailAddress: ownerEmail,
          phoneNumber: ownerPhone,
          customMessage: 'Kontaktirajte nas za rezervaciju!',
        ),
        emailConfig: const EmailNotificationConfig(), // Default disabled
        taxLegalConfig: const TaxLegalConfig(), // Default enabled
        requireOwnerApproval: true, // Owner approval required
        weekendDays: weekendDays ??
            const [5, 6], // Use provided or default to Fri, Sat
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await _settingsDocRef(propertyId, unitId).set(settings.toFirestore());

      LoggingService.log(
        'Default settings created for unit: $unitId',
        tag: _logTag,
      );
    } catch (e) {
      LoggingService.log('Error creating default settings: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Update widget settings
  Future<void> updateWidgetSettings(WidgetSettings settings) async {
    try {
      final updatedSettings = settings.copyWith(
        updatedAt: DateTime.now().toUtc(),
      );

      // DEBUG: Log the exact path being used
      final docPath =
          'properties/${settings.propertyId}/widget_settings/${settings.id}';
      LoggingService.logInfo('updateWidgetSettings: Saving to path: $docPath');
      LoggingService.logInfo(
        'updateWidgetSettings: settings.id=${settings.id}, propertyId=${settings.propertyId}',
      );

      await _settingsDocRef(
        settings.propertyId,
        settings.id,
      ).set(updatedSettings.toFirestore(), SetOptions(merge: true));

      LoggingService.logSuccess(
        'Settings updated for unit: ${settings.id}',
        tag: _logTag,
      );
    } catch (e) {
      LoggingService.log('Error updating settings: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Update widget mode only
  Future<void> updateWidgetMode({
    required String propertyId,
    required String unitId,
    required WidgetMode widgetMode,
  }) async {
    try {
      await _settingsDocRef(propertyId, unitId).update({
        'widget_mode': widgetMode.toStringValue(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log(
        'Widget mode updated to: ${widgetMode.toStringValue()}',
        tag: _logTag,
      );
    } catch (e) {
      LoggingService.log('Error updating widget mode: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Update Stripe configuration
  Future<void> updateStripeConfig({
    required String propertyId,
    required String unitId,
    required StripePaymentConfig config,
  }) async {
    try {
      await _settingsDocRef(propertyId, unitId).update({
        'stripe_config': config.toMap(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Stripe config updated', tag: _logTag);
    } catch (e) {
      LoggingService.log('Error updating Stripe config: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Update bank transfer configuration
  Future<void> updateBankTransferConfig({
    required String propertyId,
    required String unitId,
    required BankTransferConfig config,
  }) async {
    try {
      await _settingsDocRef(propertyId, unitId).update({
        'bank_transfer_config': config.toMap(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Bank transfer config updated', tag: _logTag);
    } catch (e) {
      LoggingService.log(
        'Error updating bank transfer config: $e',
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Update contact options
  Future<void> updateContactOptions({
    required String propertyId,
    required String unitId,
    required ContactOptions contactOptions,
  }) async {
    try {
      await _settingsDocRef(propertyId, unitId).update({
        'contact_options': contactOptions.toMap(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Contact options updated', tag: _logTag);
    } catch (e) {
      LoggingService.log('Error updating contact options: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Delete widget settings (when unit is deleted)
  Future<void> deleteWidgetSettings({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      await _settingsDocRef(propertyId, unitId).delete();

      LoggingService.log('Settings deleted for unit: $unitId', tag: _logTag);
    } catch (e) {
      LoggingService.log('Error deleting settings: $e', tag: _logTag);
      rethrow;
    }
  }

  /// Get all widget settings for a property
  Future<List<WidgetSettings>> getAllPropertySettings(String propertyId) async {
    try {
      final snapshot = await _settingsCollectionRef(propertyId).get();

      return snapshot.docs
          .map((doc) {
            try {
              return WidgetSettings.fromFirestore(doc);
            } catch (e) {
              LoggingService.log(
                'Error parsing widget settings doc ${doc.id}: $e',
                tag: _logTag,
              );
              return null;
            }
          })
          .whereType<WidgetSettings>()
          .toList();
    } catch (e) {
      LoggingService.log(
        'Error getting all property settings: $e',
        tag: _logTag,
      );
      return [];
    }
  }

  /// Check if settings exist for a unit
  Future<bool> settingsExist({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      final doc = await _settingsDocRef(propertyId, unitId).get();
      return doc.exists;
    } catch (e) {
      LoggingService.log('Error checking if settings exist: $e', tag: _logTag);
      return false;
    }
  }

  /// Update email verification requirement for all units in a property
  ///
  /// This is a property-wide setting that should apply to all units.
  /// When email verification is enabled/disabled, it affects all units.
  Future<void> updateEmailVerificationForAllUnits({
    required String propertyId,
    required bool requireEmailVerification,
  }) async {
    try {
      final snapshot = await _settingsCollectionRef(propertyId).get();

      if (snapshot.docs.isEmpty) {
        LoggingService.log(
          'No widget settings found for property: $propertyId',
          tag: _logTag,
        );
        return;
      }

      WriteBatch batch = _firestore.batch();
      int updateCount = 0;
      int totalUpdated = 0;

      for (final doc in snapshot.docs) {
        // Update email_config with new require_email_verification value
        batch.update(doc.reference, {
          'email_config.require_email_verification': requireEmailVerification,
          'updated_at': Timestamp.now(),
        });
        updateCount++;
        totalUpdated++;

        // Commit batch when reaching max size and create new batch
        if (updateCount >= _maxBatchSize) {
          await batch.commit();
          batch = _firestore.batch();
          updateCount = 0;
        }
      }

      // Commit remaining operations
      if (updateCount > 0) {
        await batch.commit();
      }

      LoggingService.log(
        'Email verification updated for $totalUpdated units in property: $propertyId',
        tag: _logTag,
      );
    } catch (e) {
      LoggingService.log(
        'Error updating email verification for all units: $e',
        tag: _logTag,
      );
      rethrow;
    }
  }
}
