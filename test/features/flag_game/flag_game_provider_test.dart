import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voidguess/data/models/country.dart';
import 'package:voidguess/data/repositories/country_repository.dart';
import 'package:voidguess/features/flag_game/providers/flag_game_provider.dart';

class _FakeCountryRepository extends CountryRepository {
  _FakeCountryRepository(this.countries);

  final List<Country> countries;

  @override
  Future<List<Country>> getCountries() async => countries;

  @override
  Future<Country> getRandomCountry({List<int>? excludeIds}) async {
    return countries.firstWhere(
      (country) => excludeIds == null || !excludeIds.contains(country.id),
    );
  }

  @override
  Future<List<Country>> getOptions({required Country correct}) async {
    return [
      correct,
      ...countries.where((country) => country.id != correct.id).take(5),
    ];
  }
}

final _countries = List.generate(
  7,
  (index) => Country(
    id: index + 1,
    name: {'fr': 'Pays ${index + 1}', 'en': 'Country ${index + 1}'},
    code: 'C$index',
    difficulty: 1,
  ),
);

void main() {
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        countryRepositoryProvider.overrideWithValue(
          _FakeCountryRepository(_countries),
        ),
      ],
    );
  }

  test('timeout records an automatic failed flag answer', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier = container.read(flagGameProvider.notifier);

    await notifier.startRun();
    for (var i = 0; i < 15; i++) {
      notifier.tick();
    }

    final state = container.read(flagGameProvider);

    expect(state.phase, FlagGamePhase.feedback);
    expect(state.isCorrect, isFalse);
    expect(state.selectedCountryId, -1);
    expect(state.results.single.correct, isFalse);
    expect(state.results.single.score, 0);
  });

  test(
    'next flag round excludes already used countries and alternates type',
    () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(flagGameProvider.notifier);

      await notifier.startRun();
      final firstState = container.read(flagGameProvider);
      await notifier.submitAnswer(firstState.correctCountry!);
      await notifier.nextItem();

      final secondState = container.read(flagGameProvider);

      expect(firstState.correctCountry!.id, 1);
      expect(secondState.correctCountry!.id, 2);
      expect(secondState.usedCountryIds, [1, 2]);
      expect(secondState.roundType, FlagRoundType.flagToName);
      expect(
        secondState.options.map((country) => country.id).toSet(),
        contains(secondState.correctCountry!.id),
      );
    },
  );
}
