import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bookbed/shared/providers/repository_providers.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/unit_wizard/state/unit_wizard_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/unit_wizard/state/unit_wizard_state.dart';
import 'package:bookbed/shared/models/unit_model.dart';
import 'package:bookbed/shared/repositories/unit_repository.dart';

class MockUnitRepository extends Mock implements UnitRepository {}

void main() {
  group('UnitWizardNotifier', () {
    late ProviderContainer container;
    late MockUnitRepository mockUnitRepository;

    setUp(() {
      mockUnitRepository = MockUnitRepository();
      container = ProviderContainer(
        overrides: [
          unitRepositoryProvider.overrideWithValue(mockUnitRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('build', () {
      test('creates empty draft when no unitId provided', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        final draft = await container.read(
          unitWizardNotifierProvider(null).future,
        );

        expect(draft, const UnitWizardDraft());
        verifyNever(() => mockUnitRepository.fetchUnitById(any()));
        subscription.close();
      });

      test('creates draft from unit when unitId provided', () async {
        final unitId = 'test-unit-id';
        final unit = UnitModel(
          id: unitId,
          propertyId: 'test-property-id',
          name: 'Test Unit',
          pricePerNight: 100.0,
          maxGuests: 4,
          createdAt: DateTime.now(),
        );
        when(
          () => mockUnitRepository.fetchUnitById(unitId),
        ).thenAnswer((_) async => unit);

        final subscription = container.listen(
          unitWizardNotifierProvider(unitId),
          (_, __) {},
        );

        final draft = await container.read(
          unitWizardNotifierProvider(unitId).future,
        );

        expect(draft.unitId, unitId);
        expect(draft.name, 'Test Unit');
        verify(() => mockUnitRepository.fetchUnitById(unitId)).called(1);
        subscription.close();
      });

      test(
        'creates empty draft and ignores error when fetchUnitById fails',
        () async {
          final unitId = 'test-unit-id';
          when(
            () => mockUnitRepository.fetchUnitById(unitId),
          ).thenThrow(Exception('Failed to load'));

          final subscription = container.listen(
            unitWizardNotifierProvider(unitId),
            (_, __) {},
          );

          final draft = await container.read(
            unitWizardNotifierProvider(unitId).future,
          );

          expect(draft, const UnitWizardDraft());
          verify(() => mockUnitRepository.fetchUnitById(unitId)).called(1);
          subscription.close();
        },
      );

      test(
        'creates empty draft and ignores when fetchUnitById returns null',
        () async {
          final unitId = 'test-unit-id';
          when(
            () => mockUnitRepository.fetchUnitById(unitId),
          ).thenAnswer((_) async => null);

          final subscription = container.listen(
            unitWizardNotifierProvider(unitId),
            (_, __) {},
          );

          final draft = await container.read(
            unitWizardNotifierProvider(unitId).future,
          );

          expect(draft, const UnitWizardDraft());
          verify(() => mockUnitRepository.fetchUnitById(unitId)).called(1);
          subscription.close();
        },
      );
    });

    group('updateField', () {
      test('updates a single field in the draft state', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.updateField('name', 'Updated Name');
        final state = container.read(unitWizardNotifierProvider(null)).value;

        expect(state?.name, 'Updated Name');
        subscription.close();
      });

      test('does nothing if state is null', () {
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );
        // State is loading/null initially
        notifier.updateField('name', 'Updated Name');

        final state = container.read(unitWizardNotifierProvider(null)).value;
        expect(state, null);
      });

      test('ignores unknown fields', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        final initialState = container
            .read(unitWizardNotifierProvider(null))
            .value;
        notifier.updateField('unknown_field', 'value');
        final state = container.read(unitWizardNotifierProvider(null)).value;

        expect(state, initialState);
        subscription.close();
      });
    });

    group('updateFields', () {
      test('updates multiple fields at once', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.updateFields({'name': 'New Name', 'bedrooms': 2});

        final state = container.read(unitWizardNotifierProvider(null)).value;

        expect(state?.name, 'New Name');
        expect(state?.bedrooms, 2);
        subscription.close();
      });
    });

    group('navigation', () {
      test('goToNextStep increments currentStep', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          1,
        );

        notifier.goToNextStep();

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          2,
        );
        subscription.close();
      });

      test('goToNextStep does not go beyond max step (4)', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.jumpToStep(4);
        notifier.goToNextStep();

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          4,
        );
        subscription.close();
      });

      test('goToPreviousStep decrements currentStep', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.jumpToStep(3);
        notifier.goToPreviousStep();

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          2,
        );
        subscription.close();
      });

      test('goToPreviousStep does not go below min step (1)', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          1,
        );
        notifier.goToPreviousStep();

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          1,
        );
        subscription.close();
      });

      test('jumpToStep sets specific step', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.jumpToStep(3);

        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          3,
        );
        subscription.close();
      });

      test('jumpToStep ignores out of bounds steps', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.jumpToStep(5); // max is 4
        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          1,
        );

        notifier.jumpToStep(0); // min is 1
        expect(
          container.read(unitWizardNotifierProvider(null)).value?.currentStep,
          1,
        );

        subscription.close();
      });
    });

    group('step completion', () {
      test('markStepCompleted adds step to completedSteps', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.markStepCompleted(1);

        expect(
          container
              .read(unitWizardNotifierProvider(null))
              .value
              ?.completedSteps[1],
          true,
        );
        subscription.close();
      });

      test('markStepSkipped adds step to skippedSteps', () async {
        final subscription = container.listen(
          unitWizardNotifierProvider(null),
          (_, __) {},
        );

        await container.read(unitWizardNotifierProvider(null).future);
        final notifier = container.read(
          unitWizardNotifierProvider(null).notifier,
        );

        notifier.markStepSkipped(2);

        expect(
          container
              .read(unitWizardNotifierProvider(null))
              .value
              ?.skippedSteps[2],
          true,
        );
        subscription.close();
      });
    });
  });
}
