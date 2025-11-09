import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../core/services/logging_service.dart';

/// Repository for managing widget settings in Firestore
/// Path: properties/{propertyId}/widget_settings/{unitId}
class FirebaseWidgetSettingsRepository {
  final FirebaseFirestore _firestore;

  FirebaseWidgetSettingsRepository(this._firestore);

  /// Get widget settings for a specific unit
  Future<WidgetSettings?> getWidgetSettings({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return WidgetSettings.fromFirestore(doc);
    } catch (e) {
      LoggingService.log('Error getting settings: $e', tag: 'WidgetSettingsRepository');
      return null;
    }
  }

  /// Watch widget settings for real-time updates
  Stream<WidgetSettings?> watchWidgetSettings({
    required String propertyId,
    required String unitId,
  }) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('widget_settings')
        .doc(unitId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return WidgetSettings.fromFirestore(doc);
    });
  }

  /// Create default widget settings for a new unit
  Future<void> createDefaultSettings({
    required String propertyId,
    required String unitId,
    String? ownerEmail,
    String? ownerPhone,
  }) async {
    try {
      final settings = WidgetSettings(
        id: unitId,
        propertyId: propertyId,
        widgetMode: WidgetMode.calendarOnly, // Default to calendar only (show availability + contact)
        contactOptions: ContactOptions(
          showEmail: true,
          emailAddress: ownerEmail,
          showPhone: true,
          phoneNumber: ownerPhone,
          showWhatsApp: false,
          customMessage: 'Kontaktirajte nas za rezervaciju!',
        ),
        emailConfig: const EmailNotificationConfig(), // Default disabled email config
        taxLegalConfig: const TaxLegalConfig(), // Default enabled tax/legal config
        requireOwnerApproval: true, // Owner approval required for bookings
        allowGuestCancellation: true,
        cancellationDeadlineHours: 48,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .set(settings.toFirestore());

      LoggingService.log('Default settings created for unit: $unitId', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error creating default settings: $e', tag: 'WidgetSettingsRepository');
      rethrow;
    }
  }

  /// Update widget settings
  Future<void> updateWidgetSettings(WidgetSettings settings) async {
    try {
      final updatedSettings = settings.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('properties')
          .doc(settings.propertyId)
          .collection('widget_settings')
          .doc(settings.id)
          .set(updatedSettings.toFirestore(), SetOptions(merge: true));

      LoggingService.log('Settings updated for unit: ${settings.id}', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error updating settings: $e', tag: 'WidgetSettingsRepository');
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
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .update({
        'widget_mode': widgetMode.toStringValue(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Widget mode updated to: ${widgetMode.toStringValue()}', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error updating widget mode: $e', tag: 'WidgetSettingsRepository');
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
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .update({
        'stripe_config': config.toMap(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Stripe config updated', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error updating Stripe config: $e', tag: 'WidgetSettingsRepository');
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
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .update({
        'bank_transfer_config': config.toMap(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Bank transfer config updated', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error updating bank transfer config: $e', tag: 'WidgetSettingsRepository');
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
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .update({
        'contact_options': contactOptions.toMap(),
        'updated_at': Timestamp.now(),
      });

      LoggingService.log('Contact options updated', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error updating contact options: $e', tag: 'WidgetSettingsRepository');
      rethrow;
    }
  }

  /// Delete widget settings (when unit is deleted)
  Future<void> deleteWidgetSettings({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .delete();

      LoggingService.log('Settings deleted for unit: $unitId', tag: 'WidgetSettingsRepository');
    } catch (e) {
      LoggingService.log('Error deleting settings: $e', tag: 'WidgetSettingsRepository');
      rethrow;
    }
  }

  /// Get all widget settings for a property
  Future<List<WidgetSettings>> getAllPropertySettings(String propertyId) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .get();

      return snapshot.docs
          .map((doc) => WidgetSettings.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggingService.log('Error getting all property settings: $e', tag: 'WidgetSettingsRepository');
      return [];
    }
  }

  /// Check if settings exist for a unit
  Future<bool> settingsExist({
    required String propertyId,
    required String unitId,
  }) async {
    try {
      final doc = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unitId)
          .get();

      return doc.exists;
    } catch (e) {
      LoggingService.log('Error checking if settings exist: $e', tag: 'WidgetSettingsRepository');
      return false;
    }
  }
}
