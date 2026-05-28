import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voidguess/data/models/item.dart';
import 'package:voidguess/data/repositories/item_repository.dart';
import 'package:voidguess/features/game/providers/game_provider.dart';

class _FakeItemRepository extends ItemRepository {
  _FakeItemRepository(this.items);

  final List<Item> items;
  var _index = 0;

  @override
  Future<Item> getRandomItem({String? category, int? difficulty}) async {
    final item = items[_index % items.length];
    _index++;
    return item;
  }
}

const _testItem = Item(
  id: 1,
  name: {'fr': 'AB', 'en': 'AB'},
  year: 2001,
  difficulty: 1,
  hint: {'fr': 'Test', 'en': 'Test'},
  category: 'game',
);

void main() {
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(
          _FakeItemRepository(const [_testItem]),
        ),
      ],
    );
  }

  test(
    'classic scoring accounts for revealed letters and hint penalty',
    () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final notifier = container.read(gameProvider.notifier);

      await notifier.startRun(mode: RunMode.quickNormal, category: 'game');
      notifier.useHint();
      notifier.revealNextLetter();
      notifier.submitGuess('ab');

      final state = container.read(gameProvider);

      expect(state.isFinished, isTrue);
      expect(state.isRunFinished, isFalse);
      expect(state.score, 250);
      expect(state.itemResults.single.found, isTrue);
      expect(state.itemResults.single.lettersRevealed, 1);
      expect(state.itemResults.single.usedHint, isTrue);
    },
  );

  test('hardcore run ends immediately on a wrong guess', () async {
    final container = buildContainer();
    addTearDown(container.dispose);

    final notifier = container.read(gameProvider.notifier);

    await notifier.startRun(mode: RunMode.quickHardcore, category: 'game');
    notifier.submitGuess('wrong answer');

    final state = container.read(gameProvider);

    expect(state.isFinished, isTrue);
    expect(state.isLost, isTrue);
    expect(state.isRunFinished, isTrue);
    expect(state.itemResults, hasLength(1));
    expect(state.itemResults.single.score, 0);
    expect(state.currentItemIndex, 0);
  });
}
