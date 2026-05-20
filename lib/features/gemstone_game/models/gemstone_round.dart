import 'dart:math';

import 'gemstone.dart';

List<Gemstone> generateGemstoneRun({int count = 10, Random? random}) {
  final pool = [...gemstones]..shuffle(random ?? Random());
  return pool.take(count).toList();
}

Gemstone pickGemstone({required List<int> excludeIds, Random? random}) {
  final rng = random ?? Random();
  final available = gemstones
      .where((gemstone) => !excludeIds.contains(gemstone.id))
      .toList();
  final pool = available.isEmpty ? [...gemstones] : available;
  return pool[rng.nextInt(pool.length)];
}

List<Gemstone> buildGemstoneOptions({
  required Gemstone correct,
  int optionCount = 6,
  Random? random,
}) {
  final rng = random ?? Random();
  final distractors =
      gemstones.where((gemstone) => gemstone.id != correct.id).toList()
        ..shuffle(rng);
  return [correct, ...distractors.take(optionCount - 1)]..shuffle(rng);
}

List<int> buildAlternatingGemstoneRoundTypes({int count = 10}) {
  return List.generate(count, (index) => index % 2);
}
