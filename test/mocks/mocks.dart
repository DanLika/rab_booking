import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mock Supabase Client
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockPostgrestClient extends Mock implements PostgrestClient {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {}

// Mock Repositories
class MockPropertyRepository extends Mock {}
class MockAuthRepository extends Mock {}
class MockBookingRepository extends Mock {}
class MockPaymentService extends Mock {}

/// Register fallback values for mocktail
void registerFallbackValues() {
  // Register DateTime
  registerFallbackValue(DateTime(2025, 1, 1));

  // Register Uri
  registerFallbackValue(Uri.parse('https://example.com'));

  // Add more fallback values as needed when models are created
}
