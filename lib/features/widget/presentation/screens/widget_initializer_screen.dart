import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/minimalist_colors.dart';
import '../../../owner_dashboard/presentation/providers/owner_properties_provider.dart';
import '../../../../shared/models/property_model.dart';

/// Widget Initializer Screen
/// Validates property and unit IDs from URL and redirects to enhanced room selection flow
///
/// URL Format: /?property=PROPERTY_ID&unit=UNIT_ID
/// OR slug-based: /booking/{unitSlug} (resolved to unit ID by router)
///
/// This screen:
/// 1. Parses property and unit IDs from URL query parameters OR uses pre-resolved unit ID
/// 2. Validates that both property and unit exist in Firebase
/// 3. Redirects to /rooms?property=PROPERTY_ID&unit=UNIT_ID with validated data
class WidgetInitializerScreen extends ConsumerStatefulWidget {
  const WidgetInitializerScreen({super.key, this.preResolvedUnitId});

  /// Pre-resolved unit ID from slug-based route
  /// If provided, skips URL parsing and uses this ID directly
  final String? preResolvedUnitId;

  @override
  ConsumerState<WidgetInitializerScreen> createState() =>
      _WidgetInitializerScreenState();
}

class _WidgetInitializerScreenState
    extends ConsumerState<WidgetInitializerScreen> {
  bool _isValidating = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateAndRedirect();
    });
  }

  Future<void> _validateAndRedirect() async {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      String? unitId;
      String? propertyId;

      // Check if we have a pre-resolved unit ID (from slug-based route)
      if (widget.preResolvedUnitId != null) {
        unitId = widget.preResolvedUnitId;

        // For slug-based routes, we need to find the property ID
        // We'll query the unit to get its propertyId
        final unitData = await _getUnitData(unitId!);
        if (unitData == null) {
          setState(() {
            _validationError = 'Unit not found.\n\nUnit ID: $unitId';
            _isValidating = false;
          });
          return;
        }

        propertyId = unitData['property_id'] as String?;
        if (propertyId == null) {
          setState(() {
            _validationError =
                'Property ID not found for unit.\n\nUnit ID: $unitId';
            _isValidating = false;
          });
          return;
        }
      } else {
        // Parse property and unit IDs from URL query parameters
        final uri = Uri.base;
        propertyId = uri.queryParameters['property'];
        unitId = uri.queryParameters['unit'];

        // Validate both parameters are provided
        if (propertyId == null || propertyId.isEmpty) {
          setState(() {
            _validationError =
                'Missing property parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
            _isValidating = false;
          });
          return;
        }

        if (unitId == null || unitId.isEmpty) {
          setState(() {
            _validationError =
                'Missing unit parameter in URL.\n\nPlease use: ?property=PROPERTY_ID&unit=UNIT_ID';
            _isValidating = false;
          });
          return;
        }
      }

      // Fetch property data first
      PropertyModel? property;
      try {
        property = await ref.read(propertyByIdProvider(propertyId).future);
      } catch (fetchError) {
        setState(() {
          _validationError =
              'Error fetching property from Firestore.\n\nProperty ID: $propertyId\n\nError: $fetchError\n\n[DEBUG v2.2: Fetch exception caught]';
          _isValidating = false;
        });
        return;
      }

      if (property == null) {
        setState(() {
          _validationError =
              'Property not found in database.\n\nProperty ID: $propertyId\n\n[DEBUG v2.2: Property returned null]';
          _isValidating = false;
        });
        return;
      }

      // Fetch unit data from specific property
      final unit = await ref.read(unitByIdProvider(propertyId, unitId).future);

      if (unit == null) {
        setState(() {
          _validationError =
              'Unit not found.\n\nUnit ID: $unitId\nProperty ID: $propertyId';
          _isValidating = false;
        });
        return;
      }

      // Validation successful - redirect based on use case
      // If unit is specified → direct calendar view (for embedded widget)
      // If only property → room selection (for multi-unit selection)
      if (mounted) {
        if (unitId.isNotEmpty) {
          // Unit specified → direct calendar for that unit
          context.pushReplacement(
            '/calendar?property=$propertyId&unit=$unitId',
          );
        } else {
          // Only property → show room selection
          context.pushReplacement('/rooms?property=$propertyId');
        }
      }
    } catch (e) {
      setState(() {
        _validationError = 'Error loading widget:\n\n$e';
        _isValidating = false;
      });
    }
  }

  /// Get unit data from Firestore using collection group query
  /// Returns unit data map with property_id included
  Future<Map<String, dynamic>?> _getUnitData(String unitId) async {
    try {
      // Query units collection group to find this unit
      final querySnapshot = await ref.read(
        unitByIdAcrossPropertiesProvider(unitId).future,
      );

      if (querySnapshot == null) {
        return null;
      }

      // Return unit data including property_id
      return {
        'id': querySnapshot.id,
        'property_id': querySnapshot.propertyId,
        'name': querySnapshot.name,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen
    if (_isValidating) {
      return Scaffold(
        backgroundColor: MinimalistColors.backgroundPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: MinimalistColors.buttonPrimary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading booking widget...',
                style: TextStyle(
                  fontSize: 16,
                  color: MinimalistColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Validating property information',
                style: TextStyle(
                  fontSize: 14,
                  color: MinimalistColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen
    return Scaffold(
      backgroundColor: MinimalistColors.backgroundPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: MinimalistColors.error,
              ),
              const SizedBox(height: 24),
              const Text(
                'Configuration Error',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: MinimalistColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _validationError ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: MinimalistColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _validateAndRedirect,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MinimalistColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
