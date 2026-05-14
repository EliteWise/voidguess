import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voidguess/features/gemstone_game/providers/gemstone_game_provider.dart';

void main() {
  test(
    'gemstone game starts with six options and records a correct answer',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(gemstoneGameProvider.notifier).startRun();
      final state = container.read(gemstoneGameProvider);

      expect(state.correctGemstone, isNotNull);
      expect(state.options.length, 6);
      expect(
        state.options.any(
          (gemstone) => gemstone.id == state.correctGemstone!.id,
        ),
        isTrue,
      );

      await container
          .read(gemstoneGameProvider.notifier)
          .submitAnswer(state.correctGemstone!);
      final answeredState = container.read(gemstoneGameProvider);

      expect(answeredState.phase, GemstoneGamePhase.feedback);
      expect(answeredState.correctCount, 1);
      expect(answeredState.totalScore, greaterThan(0));
    },
  );
}
