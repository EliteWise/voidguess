import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:voidguess/features/flag_game/models/flag_round.dart';
import 'package:voidguess/features/gemstone_game/models/gemstone.dart';
import 'package:voidguess/features/gemstone_game/models/gemstone_round.dart';
import 'package:voidguess/features/shared/game_scoring.dart';
import 'package:voidguess/features/space_game/models/space_distance_round.dart';

void main() {
  test('fast answer scoring is shared across short-answer games', () {
    expect(fastAnswerScore(0), 1000);
    expect(fastAnswerScore(2), 1000);
    expect(fastAnswerScore(3), 700);
    expect(fastAnswerScore(6), 700);
    expect(fastAnswerScore(7), 400);
    expect(fastAnswerScore(14), 400);
    expect(fastAnswerScore(15), 0);
  });

  test('flag round types alternate in the shared helper', () {
    expect(buildAlternatingFlagRoundTypes(count: 6), [0, 1, 0, 1, 0, 1]);
  });

  test('gemstone options include the answer and unique distractors', () {
    final correct = gemstones[0];
    final options = buildGemstoneOptions(correct: correct, random: Random(1));

    expect(options, hasLength(6));
    expect(options.any((gemstone) => gemstone.id == correct.id), isTrue);
    expect(options.map((gemstone) => gemstone.id).toSet(), hasLength(6));
  });

  test('space distance scoring and generation are shared', () {
    final rounds = generateSpaceDistanceRounds(count: 10, random: Random(1));

    expect(rounds, hasLength(10));
    expect(
      rounds.map((round) {
        final ids = [round.leftPlanet.id, round.rightPlanet.id]..sort();
        return '${ids[0]}-${ids[1]}';
      }).toSet(),
      hasLength(10),
    );
    expect(spaceDistanceScore(0), 1000);
    expect(spaceDistanceScore(maxSpaceDistanceGuessMillionKm), 0);
  });
}
