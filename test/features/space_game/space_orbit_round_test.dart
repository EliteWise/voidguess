import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:voidguess/features/space_game/models/space_orbit_round.dart';

void main() {
  test('orbit rounds always put the correct planet between its neighbors', () {
    final rounds = generateSpaceOrbitRounds(count: 20, random: Random(1));

    expect(rounds, hasLength(20));
    for (final round in rounds) {
      expect(round.options, hasLength(4));
      expect(
        round.options.any((planet) => planet.id == round.correctPlanet.id),
        isTrue,
      );
      expect(
        round.lowerPlanet.orbitMillionKm,
        lessThan(round.correctPlanet.orbitMillionKm),
      );
      expect(
        round.correctPlanet.orbitMillionKm,
        lessThan(round.upperPlanet.orbitMillionKm),
      );
      for (final option in round.options.where(
        (planet) => planet.id != round.correctPlanet.id,
      )) {
        expect(
          isPlanetBetweenOrbits(option, round.lowerPlanet, round.upperPlanet),
          isFalse,
        );
      }
    }
  });

  test('orbit scoring stays shared for solo and multiplayer', () {
    expect(spaceOrbitScoreForAnswer(correct: false, timeSeconds: 1), 0);
    expect(spaceOrbitScoreForAnswer(correct: true, timeSeconds: 2), 1000);
    expect(spaceOrbitScoreForAnswer(correct: true, timeSeconds: 6), 700);
    expect(spaceOrbitScoreForAnswer(correct: true, timeSeconds: 7), 400);
  });
}
