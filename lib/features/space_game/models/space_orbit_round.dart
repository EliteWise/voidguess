import 'dart:math';

import 'space_planet.dart';

class SpaceOrbitRound {
  final SpacePlanet lowerPlanet;
  final SpacePlanet upperPlanet;
  final SpacePlanet correctPlanet;
  final List<SpacePlanet> options;

  const SpaceOrbitRound({
    required this.lowerPlanet,
    required this.upperPlanet,
    required this.correctPlanet,
    required this.options,
  });
}

class SpaceOrbitRoundResult {
  final SpacePlanet correctPlanet;
  final SpacePlanet? selectedPlanet;
  final bool correct;
  final int timeSeconds;
  final int score;

  const SpaceOrbitRoundResult({
    required this.correctPlanet,
    required this.selectedPlanet,
    required this.correct,
    required this.timeSeconds,
    required this.score,
  });
}

SpaceOrbitRound generateSpaceOrbitRound({Random? random}) {
  final rng = random ?? Random();
  final ordered = [...spacePlanets]
    ..sort((a, b) => a.orbitMillionKm.compareTo(b.orbitMillionKm));
  final correctIndex = 1 + rng.nextInt(ordered.length - 2);
  return buildSpaceOrbitRound(ordered[correctIndex], random: rng);
}

List<SpaceOrbitRound> generateSpaceOrbitRounds({
  int count = 10,
  Random? random,
}) {
  final rng = random ?? Random();
  final ordered = [...spacePlanets]
    ..sort((a, b) => a.orbitMillionKm.compareTo(b.orbitMillionKm));
  final correctPlanets = ordered.sublist(1, ordered.length - 1);
  final rounds = <SpaceOrbitRound>[];

  while (rounds.length < count) {
    final correct = correctPlanets[rounds.length % correctPlanets.length];
    rounds.add(
      buildSpaceOrbitRound(correct, orderedPlanets: ordered, random: rng),
    );
  }

  rounds.shuffle(rng);
  return rounds;
}

SpaceOrbitRound buildSpaceOrbitRound(
  SpacePlanet correctPlanet, {
  List<SpacePlanet>? orderedPlanets,
  Random? random,
}) {
  final rng = random ?? Random();
  final ordered =
      orderedPlanets ??
      ([...spacePlanets]
        ..sort((a, b) => a.orbitMillionKm.compareTo(b.orbitMillionKm)));
  final correctIndex = ordered.indexWhere(
    (planet) => planet.id == correctPlanet.id,
  );
  if (correctIndex <= 0 || correctIndex >= ordered.length - 1) {
    throw ArgumentError('Correct planet must be between two orbit neighbors.');
  }

  final lower = ordered[correctIndex - 1];
  final upper = ordered[correctIndex + 1];
  final distractors =
      ordered
          .where(
            (planet) =>
                planet.id != lower.id &&
                planet.id != upper.id &&
                planet.id != correctPlanet.id &&
                !isPlanetBetweenOrbits(planet, lower, upper),
          )
          .toList()
        ..shuffle(rng);
  final options = [correctPlanet, ...distractors.take(3)]..shuffle(rng);

  return SpaceOrbitRound(
    lowerPlanet: lower,
    upperPlanet: upper,
    correctPlanet: correctPlanet,
    options: options,
  );
}

bool isPlanetBetweenOrbits(
  SpacePlanet planet,
  SpacePlanet lower,
  SpacePlanet upper,
) {
  return planet.orbitMillionKm > lower.orbitMillionKm &&
      planet.orbitMillionKm < upper.orbitMillionKm;
}

int spaceOrbitScoreForAnswer({
  required bool correct,
  required int timeSeconds,
}) {
  if (!correct) return 0;
  if (timeSeconds < 3) return 1000;
  if (timeSeconds < 7) return 700;
  return 400;
}
