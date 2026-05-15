import 'dart:math';

class SpacePlanet {
  final int id;
  final String name;
  final String assetPath;
  final double orbitMillionKm;

  const SpacePlanet({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.orbitMillionKm,
  });
}

const List<SpacePlanet> spacePlanets = [
  SpacePlanet(
    id: 1,
    name: 'Mercure',
    assetPath: 'assets/planets/mercury.png',
    orbitMillionKm: 57.9,
  ),
  SpacePlanet(
    id: 2,
    name: 'Venus',
    assetPath: 'assets/planets/venus.png',
    orbitMillionKm: 108.2,
  ),
  SpacePlanet(
    id: 3,
    name: 'Terre',
    assetPath: 'assets/planets/earth.png',
    orbitMillionKm: 149.6,
  ),
  SpacePlanet(
    id: 4,
    name: 'Mars',
    assetPath: 'assets/planets/mars.png',
    orbitMillionKm: 227.9,
  ),
  SpacePlanet(
    id: 5,
    name: 'Jupiter',
    assetPath: 'assets/planets/jupiter.png',
    orbitMillionKm: 778.6,
  ),
  SpacePlanet(
    id: 6,
    name: 'Saturne',
    assetPath: 'assets/planets/saturn.png',
    orbitMillionKm: 1433.5,
  ),
  SpacePlanet(
    id: 7,
    name: 'Uranus',
    assetPath: 'assets/planets/uranus.png',
    orbitMillionKm: 2872.5,
  ),
  SpacePlanet(
    id: 8,
    name: 'Neptune',
    assetPath: 'assets/planets/neptune.png',
    orbitMillionKm: 4495.1,
  ),
];

double averagePlanetDistanceMillionKm(
  SpacePlanet first,
  SpacePlanet second, {
  int samples = 720,
}) {
  var sum = 0.0;
  for (var i = 0; i < samples; i++) {
    final angle = 2 * pi * i / samples;
    final a = first.orbitMillionKm;
    final b = second.orbitMillionKm;
    sum += sqrt(a * a + b * b - 2 * a * b * cos(angle));
  }
  return sum / samples;
}
