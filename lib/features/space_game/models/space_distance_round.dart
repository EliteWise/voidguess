import 'dart:math';

import 'space_planet.dart';

const double maxSpaceDistanceGuessMillionKm = 4500;
const double spaceDistanceGuessStepMillionKm = 10;

class SpaceDistanceRound {
  final SpacePlanet leftPlanet;
  final SpacePlanet rightPlanet;

  const SpaceDistanceRound({
    required this.leftPlanet,
    required this.rightPlanet,
  });

  double get actualDistanceMillionKm {
    return averagePlanetDistanceMillionKm(leftPlanet, rightPlanet);
  }
}

SpaceDistanceRound generateSpaceDistanceRound({Random? random}) {
  final planets = [...spacePlanets]..shuffle(random ?? Random());
  return SpaceDistanceRound(leftPlanet: planets[0], rightPlanet: planets[1]);
}

List<SpaceDistanceRound> generateSpaceDistanceRounds({
  int count = 10,
  Random? random,
}) {
  final rng = random ?? Random();
  final rounds = <SpaceDistanceRound>[];
  final randomPlanets = [...spacePlanets];

  while (rounds.length < count) {
    randomPlanets.shuffle(rng);
    final left = randomPlanets[0];
    final right = randomPlanets[1];
    final duplicate = rounds.any(
      (round) =>
          (round.leftPlanet.id == left.id &&
              round.rightPlanet.id == right.id) ||
          (round.leftPlanet.id == right.id && round.rightPlanet.id == left.id),
    );
    if (!duplicate) {
      rounds.add(SpaceDistanceRound(leftPlanet: left, rightPlanet: right));
    }
  }

  return rounds;
}

double spaceDistanceDifferenceMillionKm({
  required double guessMillionKm,
  required double actualMillionKm,
}) {
  return (guessMillionKm - actualMillionKm).abs();
}

int spaceDistanceScore(double differenceMillionKm) {
  final ratio = (differenceMillionKm / maxSpaceDistanceGuessMillionKm).clamp(
    0.0,
    1.0,
  );
  return (1000 * (1 - ratio)).round();
}

String formatSpaceDistance(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)} Md km';
  }
  return '${value.round()} M km';
}
