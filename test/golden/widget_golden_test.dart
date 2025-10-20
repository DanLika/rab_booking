import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:rab_booking/shared/widgets/property_card.dart';
import 'package:rab_booking/shared/widgets/error_state_widget.dart';
import 'package:rab_booking/shared/models/property_model.dart';

/// Golden tests for visual regression testing
/// These tests capture screenshots and compare against baseline images
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('Property Card Golden Tests', () {
    testGoldens('PropertyCard renders correctly in light mode',
        (WidgetTester tester) async {
      final property = PropertyModel(
        id: '1',
        name: 'Beautiful Apartment',
        location: 'Rab, Croatia',
        pricePerNight: 150.0,
        rating: 4.8,
        reviewCount: 124,
        images: [
          'https://via.placeholder.com/400x300',
        ],
        bedrooms: 2,
        bathrooms: 1,
        maxGuests: 4,
        description: 'A beautiful apartment',
        amenities: [],
        ownerId: 'owner1',
        ownerName: 'John Doe',
        propertyType: PropertyType.apartment,
        lat: 44.7555,
        lng: 14.7594,
      );

      await tester.pumpWidgetBuilder(
        PropertyCard(
          property: property,
          onTap: () {},
        ),
        surfaceSize: const Size(400, 500),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
      );

      await screenMatchesGolden(tester, 'property_card_light');
    });

    testGoldens('PropertyCard renders correctly in dark mode',
        (WidgetTester tester) async {
      final property = PropertyModel(
        id: '1',
        name: 'Beautiful Apartment',
        location: 'Rab, Croatia',
        pricePerNight: 150.0,
        rating: 4.8,
        reviewCount: 124,
        images: [
          'https://via.placeholder.com/400x300',
        ],
        bedrooms: 2,
        bathrooms: 1,
        maxGuests: 4,
        description: 'A beautiful apartment',
        amenities: [],
        ownerId: 'owner1',
        ownerName: 'John Doe',
        propertyType: PropertyType.apartment,
        lat: 44.7555,
        lng: 14.7594,
      );

      await tester.pumpWidgetBuilder(
        PropertyCard(
          property: property,
          onTap: () {},
        ),
        surfaceSize: const Size(400, 500),
        wrapper: materialAppWrapper(
          theme: ThemeData.dark(),
        ),
      );

      await screenMatchesGolden(tester, 'property_card_dark');
    });

    testGoldens('PropertyCard responsive variants',
        (WidgetTester tester) async {
      final property = PropertyModel(
        id: '1',
        name: 'Beautiful Apartment with a Very Long Name That Might Wrap',
        location: 'Rab, Croatia',
        pricePerNight: 150.0,
        rating: 4.8,
        reviewCount: 124,
        images: [
          'https://via.placeholder.com/400x300',
        ],
        bedrooms: 2,
        bathrooms: 1,
        maxGuests: 4,
        description: 'A beautiful apartment',
        amenities: [],
        ownerId: 'owner1',
        ownerName: 'John Doe',
        propertyType: PropertyType.apartment,
        lat: 44.7555,
        lng: 14.7594,
      );

      final builder = GoldenBuilder.grid(
        columns: 2,
        widthToHeightRatio: 1,
      )
        ..addScenario(
          'Mobile (360px)',
          PropertyCard(property: property, onTap: () {}),
        )
        ..addScenario(
          'Tablet (600px)',
          SizedBox(
            width: 600,
            child: PropertyCard(property: property, onTap: () {}),
          ),
        )
        ..addScenario(
          'Desktop (1024px)',
          SizedBox(
            width: 1024,
            child: PropertyCard(property: property, onTap: () {}),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(1200, 1000),
      );

      await screenMatchesGolden(tester, 'property_card_responsive');
    });
  });

  group('Error State Golden Tests', () {
    testGoldens('ErrorStateWidget renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidgetBuilder(
        ErrorStateWidget(
          message: 'Došlo je do greške pri učitavanju podataka',
          onRetry: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'error_state_widget');
    });

    testGoldens('ErrorStateWidget without retry button',
        (WidgetTester tester) async {
      await tester.pumpWidgetBuilder(
        const ErrorStateWidget(
          message: 'Nema dostupnih podataka',
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'error_state_widget_no_retry');
    });

    testGoldens('ErrorStateWidget with custom icon',
        (WidgetTester tester) async {
      await tester.pumpWidgetBuilder(
        ErrorStateWidget(
          message: 'Nema rezultata pretrage',
          icon: Icons.search_off,
          onRetry: () {},
        ),
        surfaceSize: const Size(400, 300),
      );

      await screenMatchesGolden(tester, 'error_state_widget_custom_icon');
    });
  });

  group('Responsive Layout Golden Tests', () {
    testGoldens('App layout at different breakpoints',
        (WidgetTester tester) async {
      final builder = GoldenBuilder.grid(
        columns: 3,
        widthToHeightRatio: 0.6,
      )
        ..addScenario(
          'Mobile\n360x640',
          Container(
            width: 360,
            height: 640,
            color: Colors.white,
            child: const Center(
              child: Text('Mobile Layout'),
            ),
          ),
        )
        ..addScenario(
          'Tablet\n768x1024',
          Container(
            width: 768,
            height: 1024,
            color: Colors.white,
            child: const Center(
              child: Text('Tablet Layout'),
            ),
          ),
        )
        ..addScenario(
          'Desktop\n1440x900',
          Container(
            width: 1440,
            height: 900,
            color: Colors.white,
            child: const Center(
              child: Text('Desktop Layout'),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(2000, 1500),
      );

      await screenMatchesGolden(tester, 'responsive_layouts');
    });
  });

  group('Theme Variants Golden Tests', () {
    testGoldens('Components in light and dark themes',
        (WidgetTester tester) async {
      final builder = GoldenBuilder.grid(
        columns: 2,
        widthToHeightRatio: 1.5,
      )
        ..addScenario(
          'Light Theme',
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outline Button'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text Button'),
                  ),
                ],
              ),
            ),
          ),
        )
        ..addScenario(
          'Dark Theme',
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outline Button'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Text Button'),
                  ),
                ],
              ),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: const Size(800, 400),
      );

      await screenMatchesGolden(tester, 'theme_variants');
    });
  });
}
