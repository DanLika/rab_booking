import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/data/repositories/firebase_widget_settings_repository.dart';
import 'package:rab_booking/features/widget/domain/models/widget_mode.dart';
import 'package:rab_booking/features/widget/domain/models/widget_settings.dart';

void main() {
  group('FirebaseWidgetSettingsRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseWidgetSettingsRepository repository;

    const testPropertyId = 'property123';
    const testUnitId = 'unit123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseWidgetSettingsRepository(fakeFirestore);
    });

    group('constructor', () {
      test('initializes with Firestore instance', () {
        expect(repository, isNotNull);
      });
    });

    group('getWidgetSettings', () {
      test('returns null when no settings exist', () async {
        final settings = await repository.getWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(settings, isNull);
      });

      test('returns settings when they exist', () async {
        // Create settings document
        await fakeFirestore
            .collection('properties')
            .doc(testPropertyId)
            .collection('widget_settings')
            .doc(testUnitId)
            .set({
          'id': testUnitId,
          'property_id': testPropertyId,
          'widget_mode': 'calendar_only',
          'require_owner_approval': true,
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });

        final settings = await repository.getWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(settings, isNotNull);
        expect(settings!.id, testUnitId);
        expect(settings.propertyId, testPropertyId);
        expect(settings.widgetMode, WidgetMode.calendarOnly);
      });
    });

    group('watchWidgetSettings', () {
      test('emits null when no settings exist', () async {
        final stream = repository.watchWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        final settings = await stream.first;
        expect(settings, isNull);
      });

      test('emits settings when they exist', () async {
        // Create settings document
        await fakeFirestore
            .collection('properties')
            .doc(testPropertyId)
            .collection('widget_settings')
            .doc(testUnitId)
            .set({
          'id': testUnitId,
          'property_id': testPropertyId,
          'widget_mode': 'booking_instant',
          'require_owner_approval': false,
          'created_at': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });

        final stream = repository.watchWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        final settings = await stream.first;
        expect(settings, isNotNull);
        expect(settings!.widgetMode, WidgetMode.bookingInstant);
      });
    });

    group('createDefaultSettings', () {
      test('creates settings with default values', () async {
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
          ownerEmail: 'owner@test.com',
          ownerPhone: '+385911234567',
        );

        final doc = await fakeFirestore
            .collection('properties')
            .doc(testPropertyId)
            .collection('widget_settings')
            .doc(testUnitId)
            .get();

        expect(doc.exists, true);
        expect(doc.data()!['widget_mode'], 'calendar_only');
        expect(doc.data()!['require_owner_approval'], true);
        expect(doc.data()!['contact_options']['email_address'], 'owner@test.com');
        expect(doc.data()!['contact_options']['phone_number'], '+385911234567');
      });
    });

    group('updateWidgetSettings', () {
      test('updates existing settings', () async {
        // First create settings
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        // Get and update settings
        final originalSettings = await repository.getWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        final updatedSettings = originalSettings!.copyWith(
          widgetMode: WidgetMode.bookingInstant,
          requireOwnerApproval: false,
        );

        await repository.updateWidgetSettings(updatedSettings);

        // Verify update
        final fetchedSettings = await repository.getWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(fetchedSettings!.widgetMode, WidgetMode.bookingInstant);
        expect(fetchedSettings.requireOwnerApproval, false);
      });
    });

    group('updateWidgetMode', () {
      test('updates only the widget mode', () async {
        // Create settings
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        // Update mode
        await repository.updateWidgetMode(
          propertyId: testPropertyId,
          unitId: testUnitId,
          widgetMode: WidgetMode.bookingPending,
        );

        // Verify
        final settings = await repository.getWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(settings!.widgetMode, WidgetMode.bookingPending);
        // Other settings should remain unchanged
        expect(settings.requireOwnerApproval, true);
      });
    });

    group('updateContactOptions', () {
      test('updates contact options', () async {
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        await repository.updateContactOptions(
          propertyId: testPropertyId,
          unitId: testUnitId,
          contactOptions: const ContactOptions(
            emailAddress: 'new@test.com',
            phoneNumber: '+385921111111',
            customMessage: 'New message',
          ),
        );

        final settings = await repository.getWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(settings!.contactOptions.emailAddress, 'new@test.com');
        expect(settings.contactOptions.phoneNumber, '+385921111111');
        expect(settings.contactOptions.customMessage, 'New message');
      });
    });

    group('deleteWidgetSettings', () {
      test('deletes settings', () async {
        // Create settings
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        // Verify exists
        var exists = await repository.settingsExist(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );
        expect(exists, true);

        // Delete
        await repository.deleteWidgetSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        // Verify deleted
        exists = await repository.settingsExist(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );
        expect(exists, false);
      });
    });

    group('settingsExist', () {
      test('returns false when no settings exist', () async {
        final exists = await repository.settingsExist(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(exists, false);
      });

      test('returns true when settings exist', () async {
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        final exists = await repository.settingsExist(
          propertyId: testPropertyId,
          unitId: testUnitId,
        );

        expect(exists, true);
      });
    });

    group('getAllPropertySettings', () {
      test('returns empty list when no settings exist', () async {
        final settings = await repository.getAllPropertySettings(testPropertyId);
        expect(settings, isEmpty);
      });

      test('returns all settings for property', () async {
        // Create settings for multiple units
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: 'unit1',
        );
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: 'unit2',
        );
        await repository.createDefaultSettings(
          propertyId: testPropertyId,
          unitId: 'unit3',
        );

        final settings = await repository.getAllPropertySettings(testPropertyId);

        expect(settings.length, 3);
        expect(settings.map((s) => s.id), containsAll(['unit1', 'unit2', 'unit3']));
      });
    });
  });
}
