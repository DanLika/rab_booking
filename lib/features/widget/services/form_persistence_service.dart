import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/logging_service.dart';
import '../../../core/utils/date_time_parser.dart';
import '../../../core/utils/safe_cast.dart';
import '../presentation/widgets/country_code_dropdown.dart';

/// Data class representing persisted form data.
///
/// Used by FormPersistenceService to save/load form state
/// when user navigates away from booking widget.
class PersistedFormData {
  final String unitId;
  final String? propertyId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String countryCode;
  final int adults;
  final int children;
  final String notes;
  final String paymentMethod;
  final bool pillBarDismissed;
  final bool hasInteractedWithBookingFlow;
  final DateTime timestamp;

  PersistedFormData({
    required this.unitId,
    this.propertyId,
    this.checkIn,
    this.checkOut,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.adults,
    required this.children,
    required this.notes,
    required this.paymentMethod,
    required this.pillBarDismissed,
    required this.hasInteractedWithBookingFlow,
    required this.timestamp,
  });

  /// Convert to JSON map for storage
  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'propertyId': propertyId,
    'checkIn': checkIn?.toIso8601String(),
    'checkOut': checkOut?.toIso8601String(),
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'countryCode': countryCode,
    'adults': adults,
    'children': children,
    'notes': notes,
    'paymentMethod': paymentMethod,
    'pillBarDismissed': pillBarDismissed,
    'hasInteractedWithBookingFlow': hasInteractedWithBookingFlow,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Create from JSON map
  ///
  /// Uses safe casting to prevent runtime errors from invalid cached data.
  /// Returns defaults if data is missing or has incorrect types.
  factory PersistedFormData.fromJson(Map<String, dynamic> json) {
    // Safely extract unitId - required field
    final unitId = safeCastString(json['unitId']);
    if (unitId == null) {
      throw ArgumentError('unitId is required but missing or invalid type');
    }

    return PersistedFormData(
      unitId: unitId,
      propertyId: safeCastString(json['propertyId']),
      checkIn: safeCastString(json['checkIn']) != null
          ? DateTimeParser.tryParse(safeCastString(json['checkIn']))
          : null,
      checkOut: safeCastString(json['checkOut']) != null
          ? DateTimeParser.tryParse(safeCastString(json['checkOut']))
          : null,
      firstName: safeCastString(json['firstName']) ?? '',
      lastName: safeCastString(json['lastName']) ?? '',
      email: safeCastString(json['email']) ?? '',
      phone: safeCastString(json['phone']) ?? '',
      countryCode: safeCastString(json['countryCode']) ?? '+385',
      adults: safeCastInt(json['adults']) ?? 2,
      children: safeCastInt(json['children']) ?? 0,
      notes: safeCastString(json['notes']) ?? '',
      paymentMethod: safeCastString(json['paymentMethod']) ?? 'stripe',
      pillBarDismissed: safeCastBool(json['pillBarDismissed']) ?? false,
      hasInteractedWithBookingFlow:
          safeCastBool(json['hasInteractedWithBookingFlow']) ?? false,
      timestamp: DateTimeParser.parseOrDefault(
        safeCastString(json['timestamp']),
        DateTime.now(),
      ),
    );
  }

  /// Get country from country code
  Country get country {
    return countries.firstWhere(
      (c) => c.dialCode == countryCode,
      orElse: () => defaultCountry,
    );
  }

  /// Check if data is expired (older than 24 hours)
  bool get isExpired {
    return DateTime.now().difference(timestamp).inHours > 24;
  }
}

/// Service for persisting booking form data to localStorage.
///
/// Extracted from BookingWidgetScreen to improve testability
/// and reduce widget complexity. Uses SharedPreferences for storage.
///
/// Bug #53: Form data persistence - saves/loads form when user
/// navigates away or refreshes the page.
class FormPersistenceService {
  static const String _formDataKey = 'booking_widget_form_data';

  /// Save form data to localStorage
  ///
  /// [unitId] - The unit ID to scope the saved data
  /// [data] - The form data to save
  static Future<void> saveFormData(
    String unitId,
    PersistedFormData data,
  ) async {
    if (unitId.isEmpty) return; // Don't save if no unit selected

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_formDataKey}_$unitId',
        jsonEncode(data.toJson()),
      );
    } catch (e) {
      // Silent fail - persistence is not critical
      LoggingService.log(
        'Failed to save form data: $e',
        tag: 'FORM_PERSISTENCE',
      );
    }
  }

  /// Load saved form data from localStorage
  ///
  /// [unitId] - The unit ID to load data for
  /// Returns null if no data found or data is expired
  static Future<PersistedFormData?> loadFormData(String unitId) async {
    if (unitId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('${_formDataKey}_$unitId');

      if (savedData == null) return null;

      // Safely decode JSON and cast to Map
      final decoded = jsonDecode(savedData);
      final jsonMap = safeCastMap(decoded);

      if (jsonMap == null) {
        LoggingService.log(
          'Invalid JSON format in saved form data (not a Map)',
          tag: 'FORM_PERSISTENCE',
        );
        await clearFormData(unitId); // Clear invalid data
        return null;
      }

      final formData = PersistedFormData.fromJson(jsonMap);

      // Check if data is not too old (max 24 hours)
      if (formData.isExpired) {
        await clearFormData(unitId); // Clear old data
        return null;
      }

      // Only return if same unit
      if (formData.unitId != unitId) {
        return null;
      }

      LoggingService.log(
        '✅ Form data restored from cache (dismissed: ${formData.pillBarDismissed}, interacted: ${formData.hasInteractedWithBookingFlow})',
        tag: 'FORM_PERSISTENCE',
      );

      return formData;
    } catch (e) {
      // Silent fail - just log
      LoggingService.log(
        'Failed to load form data: $e',
        tag: 'FORM_PERSISTENCE',
      );
      return null;
    }
  }

  /// Clear saved form data from localStorage
  ///
  /// [unitId] - The unit ID to clear data for
  static Future<void> clearFormData(String unitId) async {
    if (unitId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_formDataKey}_$unitId');
      LoggingService.log('🗑️ Form data cleared', tag: 'FORM_PERSISTENCE');
    } catch (e) {
      // Silent fail
      LoggingService.log(
        'Failed to clear form data: $e',
        tag: 'FORM_PERSISTENCE',
      );
    }
  }
}
