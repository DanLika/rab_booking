import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookbed/features/owner_dashboard/data/firebase/firebase_revenue_analytics_repository.dart';
import 'package:bookbed/core/exceptions/app_exceptions.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockAggregateQuery extends Mock implements AggregateQuery {}
class FakeAggregateField extends Fake implements AggregateField {}

void main() {
  late MockFirebaseFirestore firestore;
  late FirebaseRevenueAnalyticsRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeAggregateField());
  });

  setUp(() {
    firestore = MockFirebaseFirestore();
    repository = FirebaseRevenueAnalyticsRepository(firestore);
  });

  group('FirebaseRevenueAnalyticsRepository Error Tests', () {
    test('getRevenueStatsOptimized throws AnalyticsException when query fails', () async {
      final mockQuery = MockQuery();
      when(() => firestore.collectionGroup(any())).thenReturn(mockQuery);
      when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'), isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueStatsOptimized(unitIds: ['u1'], unitIdToPropertyName: {'u1': 'Prop 1'}),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-stats-failed')),
      );
    });

    test('getRevenueByDaysOptimized throws AnalyticsException when query fails', () async {
      final mockQuery = MockQuery();
      when(() => firestore.collectionGroup(any())).thenReturn(mockQuery);
      when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'), isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueByDaysOptimized(unitIds: ['u1'], days: 7),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-by-days-failed')),
      );
    });

    test('getRevenueByDays throws AnalyticsException when query fails', () async {
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      when(() => firestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueByDays('owner1', 7),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-by-days-failed')),
      );
    });

    test('getTotalRevenue throws AnalyticsException when query fails', () async {
      final mockQuery = MockQuery();
      final mockAggregateQuery = MockAggregateQuery();
      when(() => firestore.collectionGroup(any())).thenReturn(mockQuery);
      when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'), isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.aggregate(any())).thenReturn(mockAggregateQuery);
      when(() => mockAggregateQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getTotalRevenue('owner1'),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/total-revenue-failed')),
      );
    });

    test('getRevenueThisMonth throws AnalyticsException when query fails', () async {
      final mockQuery = MockQuery();
      final mockAggregateQuery = MockAggregateQuery();
      when(() => firestore.collectionGroup(any())).thenReturn(mockQuery);
      when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'), isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.aggregate(any())).thenReturn(mockAggregateQuery);
      when(() => mockAggregateQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueThisMonth('owner1'),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-this-month-failed')),
      );
    });

    test('getRevenueLastMonth throws AnalyticsException when query fails', () async {
      final mockQuery = MockQuery();
      final mockAggregateQuery = MockAggregateQuery();
      when(() => firestore.collectionGroup(any())).thenReturn(mockQuery);
      when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'), isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.aggregate(any())).thenReturn(mockAggregateQuery);
      when(() => mockAggregateQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueLastMonth('owner1'),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-last-month-failed')),
      );
    });

    test('getRevenueByProperty throws AnalyticsException when query fails', () async {
      final mockCollection = MockCollectionReference();
      final mockQuery = MockQuery();
      when(() => firestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'))).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueByProperty('owner1'),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-by-property-failed')),
      );
    });

    test('getRevenueStats throws AnalyticsException when query fails', () async {
      // getRevenueStats internally calls getTotalRevenue among others.
      // Mocking the aggregate query to throw should cover this.
      final mockQuery = MockQuery();
      final mockAggregateQuery = MockAggregateQuery();

      // Fallback for independent queries running in parallel
      when(() => firestore.collection(any())).thenThrow(Exception('Firestore error'));
      when(() => firestore.collectionGroup(any())).thenReturn(mockQuery);
      when(() => mockQuery.where(any(), isEqualTo: any(named: 'isEqualTo'), whereIn: any(named: 'whereIn'), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'), isLessThanOrEqualTo: any(named: 'isLessThanOrEqualTo'))).thenReturn(mockQuery);
      when(() => mockQuery.aggregate(any())).thenReturn(mockAggregateQuery);
      when(() => mockAggregateQuery.get()).thenThrow(Exception('Firestore error'));

      expect(
        () => repository.getRevenueStats('owner1'),
        throwsA(isA<AnalyticsException>().having((e) => e.code, 'code', 'analytics/revenue-stats-failed')),
      );
    });
  });
}
