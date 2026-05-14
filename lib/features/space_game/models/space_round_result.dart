class SpaceRoundResult {
  final String leftPlanetName;
  final String rightPlanetName;
  final double guessMillionKm;
  final double actualMillionKm;
  final double differenceMillionKm;
  final int timeSeconds;
  final int score;

  const SpaceRoundResult({
    required this.leftPlanetName,
    required this.rightPlanetName,
    required this.guessMillionKm,
    required this.actualMillionKm,
    required this.differenceMillionKm,
    required this.timeSeconds,
    required this.score,
  });
}
