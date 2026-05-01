import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String _statsBox = 'stats';
  static const String _achievementsBox = 'achievements';

  // ─── Ranked ─────────────────────────────────────────────

  static const List<String> rankNames = [
    'Void', 'Bronze', 'Silver', 'Gold',
    'Platinum', 'Diamond', 'Master', 'Void Master',
  ];

  static const int vpPerRank = 10;

  // VP gagnés selon le score et le rang actuel
  // Full Hard = multiplicateur x2
  int calculateVP(int score, int rankIndex, bool isHardcore) {
    final thresholds = _vpThresholds[rankIndex];
    int vp;
    if (score < thresholds[0]) vp = -2;
    else if (score < thresholds[1]) vp = -1;
    else if (score < thresholds[2]) vp = 0;
    else if (score < thresholds[3]) vp = 1;
    else vp = 2;

    if (isHardcore) vp *= 2;
    return vp;
  }

  // Seuils [−2, −1, 0, +1, +2] pour chaque rang
  static const List<List<int>> _vpThresholds = [
    [80,   350,  750,  2500, 99999],  // Void
    [150,  600,  1200, 3000, 99999],  // Bronze
    [250,  900,  1800, 3500, 99999],  // Silver
    [400,  1400, 2600, 4300, 99999],  // Gold
    [600,  2000, 3500, 5300, 99999],  // Platinum
    [800,  2800, 4800, 6300, 99999],  // Diamond
    [1000, 3500, 5500, 7000, 99999],  // Master
    [1200, 4000, 6000, 6500, 99999],  // Void Master
  ];


  int getCurrentVP() =>
      Hive.box(_statsBox).get('currentVP', defaultValue: 0);

  int getCurrentRankIndex() =>
      Hive.box(_statsBox).get('rankIndex', defaultValue: 0);

  String getCurrentRankName() => rankNames[getCurrentRankIndex()];

  // Retourne les VP dans le rang actuel (0-9 sauf Void Master)
  int getVPInCurrentRank() {
    final totalVP = getCurrentVP();
    if (getCurrentRankIndex() >= rankNames.length - 1) {
      // Void Master — VP infinis, on retourne le total depuis Master max
      return totalVP - (vpPerRank * (rankNames.length - 1));
    }
    return totalVP % vpPerRank;
  }

  Future<int> updateRank(int score, bool isHardcore) async {
    final box = Hive.box(_statsBox);
    int rankIndex = getCurrentRankIndex();
    int totalVP = getCurrentVP();

    final vp = calculateVP(score, rankIndex, isHardcore);
    totalVP += vp;

    // Montée de rang
    while (rankIndex < rankNames.length - 1 &&
        totalVP >= (rankIndex + 1) * vpPerRank) {
      rankIndex++;
    }

    // Descente de rang — pas en dessous de Void
    while (rankIndex > 0 &&
        totalVP < rankIndex * vpPerRank) {
      rankIndex--;
    }

    // Clamp le total VP au minimum du rang actuel
    final minVP = rankIndex * vpPerRank;
    if (totalVP < minVP) totalVP = minVP;

    await box.put('currentVP', totalVP);
    await box.put('rankIndex', rankIndex);

    return vp;
  }

  // ─── Flag Ranked ─────────────────────────────────────────────────────────────

// Seuils correct/total pour -1 / 0 / +1 VP par rang
  static const List<List<int>> _flagVpThresholds = [
    [3, 4, 10],  // Void     — <3 = -1, 3 = 0, >=4 = +1
    [3, 5, 10],  // Bronze   — <3 = -1, 3-4 = 0, >=5 = +1
    [4, 5, 10],  // Silver   — <4 = -1, 4 = 0, >=5 = +1
    [4, 6, 10],  // Gold     — <4 = -1, 4-5 = 0, >=6 = +1
    [5, 6, 10],  // Platinum — <5 = -1, 5 = 0, >=6 = +1
    [5, 7, 10],  // Diamond  — <5 = -1, 5-6 = 0, >=7 = +1
    [6, 7, 10],  // Master   — <6 = -1, 6 = 0, >=7 = +1
    [6, 8, 10],  // VoidMaster — <6 = -1, 6-7 = 0, >=8 = +1
  ];

  Future<int> updateFlagRank({
    required int correctCount,
    required int totalItems,
  }) async {
    final rankIndex = getCurrentRankIndex();
    final thresholds = _flagVpThresholds[rankIndex.clamp(0, _flagVpThresholds.length - 1)];

    int vp;
    if (correctCount < thresholds[0]) {
      vp = -1;
    } else if (correctCount < thresholds[1]) {
      vp = 0;
    } else {
      vp = 1;
    }

    // Réutilise la même logique de rank up/down que Void Guess
    final box = Hive.box(_statsBox);
    int totalVP = getCurrentVP();
    int newRankIndex = rankIndex;

    totalVP += vp;

    // Rank up
    while (newRankIndex < rankNames.length - 1 &&
        totalVP >= (newRankIndex + 1) * vpPerRank) {
      newRankIndex++;
    }

    // Rank down
    while (newRankIndex > 0 && totalVP < newRankIndex * vpPerRank) {
      newRankIndex--;
    }

    // Clamp au minimum du rang
    final minVP = newRankIndex * vpPerRank;
    if (totalVP < minVP) totalVP = minVP;

    await box.put('currentVP', totalVP);
    await box.put('rankIndex', newRankIndex);

    return vp;
  }

  // ─── Runs ───────────────────────────────────────────────

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);
    await Hive.openBox(_statsBox);
    await Hive.openBox(_achievementsBox);
  }

  Future<void> saveRun({
    required int totalScore,
    required int itemsFound,
    required int totalItems,
    required int avgTimeSeconds,
    required String mode,
    required String category,
    required List<Map> itemResults,
  }) async {
    final box = Hive.box(_statsBox);
    final runs = List<Map>.from(box.get('runs', defaultValue: []));
    runs.add({
      'totalScore': totalScore,
      'itemsFound': itemsFound,
      'totalItems': totalItems,
      'avgTime': avgTimeSeconds,
      'mode': mode,
      'category': category,
      'itemResults': itemResults,
      'date': DateTime.now().toIso8601String(),
    });
    await box.put('runs', runs);
    await _updateBests(
      score: totalScore,
      avgTime: avgTimeSeconds,
      itemsFound: itemsFound,
      totalItems: totalItems,
    );
  }

  Future<void> _updateBests({
    required int score,
    required int avgTime,
    required int itemsFound,
    required int totalItems,
  }) async {
    final box = Hive.box(_statsBox);
    if (score > getBestScore()) await box.put('bestScore', score);
    if (avgTime < getBestAvgTime()) await box.put('bestAvgTime', avgTime);
  }

  List<Map> getRuns() {
    return List<Map>.from(
      Hive.box(_statsBox).get('runs', defaultValue: []),
    );
  }

  int getBestScore() =>
      Hive.box(_statsBox).get('bestScore', defaultValue: 0);

  int getBestAvgTime() =>
      Hive.box(_statsBox).get('bestAvgTime', defaultValue: 9999);

  int getTotalRuns() => getRuns().length;

  double getSuccessRate() {
    final runs = getRuns();
    if (runs.isEmpty) return 0;
    final totalFound = runs.fold<int>(0, (sum, r) => sum + (r['itemsFound'] as int));
    final totalItems = runs.fold<int>(0, (sum, r) => sum + (r['totalItems'] as int));
    if (totalItems == 0) return 0;
    return (totalFound / totalItems) * 100;
  }

  Map<String, dynamic>? getBestRun() {
    final runs = getRuns();
    if (runs.isEmpty) return null;
    runs.sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));
    return Map<String, dynamic>.from(runs.first);
  }

  // ─── Achievements ────────────────────────────────────────

  Future<void> unlockAchievement(String id) async {
    final box = Hive.box(_achievementsBox);
    final unlocked = List<String>.from(box.get('unlocked', defaultValue: []));
    if (!unlocked.contains(id)) {
      unlocked.add(id);
      await box.put('unlocked', unlocked);
    }
  }

  bool isUnlocked(String id) {
    final box = Hive.box(_achievementsBox);
    return List<String>.from(
      box.get('unlocked', defaultValue: []),
    ).contains(id);
  }

  List<String> getUnlocked() {
    return List<String>.from(
      Hive.box(_achievementsBox).get('unlocked', defaultValue: []),
    );
  }

  Future<void> checkAndUnlockAchievements({
    required int totalScore,
    required int itemsFound,
    required int totalItems,
    required int avgTime,
    required bool usedHint,
    required bool isHardcore,
    required String category,
    required List<Map> itemResults,
  }) async {
    final runs = getRuns();
    final totalRuns = runs.length;
    final hardcoreRuns = runs.where((r) =>
        (r['mode'] as String).toLowerCase().contains('hardcore')).length;
    final gameRuns = runs.where((r) => r['category'] == 'game').length;
    final movieRuns = runs.where((r) => r['category'] == 'movie').length;

    if (totalRuns == 1) await unlockAchievement('first_run');
    if (totalRuns >= 10) await unlockAchievement('veteran');
    if (totalRuns >= 50) await unlockAchievement('legend');
    if (totalRuns >= 100) await unlockAchievement('void_walker');

    if (isHardcore && itemsFound == totalItems) {
      await unlockAchievement('hardcore_survivor');
    }
    if (hardcoreRuns >= 10) await unlockAchievement('void_master');

    if (itemsFound == totalItems && totalItems == 10) {
      await unlockAchievement('perfect_run');
    }

    if (!usedHint && itemsFound == totalItems) {
      await unlockAchievement('no_hint');
    }
    if (!usedHint && itemsFound == totalItems && totalItems == 10) {
      await unlockAchievement('blindfolded');
    }

    if (totalScore >= 5000) await unlockAchievement('grand_total');
    if (avgTime <= 8) await unlockAchievement('no_time_to_think');
    if (gameRuns >= 5) await unlockAchievement('gamer');
    if (movieRuns >= 5) await unlockAchievement('cinephile');
    if (gameRuns >= 1 && movieRuns >= 1) await unlockAchievement('cultured');

    for (final result in itemResults) {
      final score = result['score'] as int? ?? 0;
      final time = result['time'] as int? ?? 99;
      final lettersRevealed = result['lettersRevealed'] as int? ?? 99;

      if (time <= 3) await unlockAchievement('speed_demon');
      if (time <= 5) await unlockAchievement('flash');
      if (score >= 800) await unlockAchievement('high_scorer');
      if (score >= 1000) await unlockAchievement('perfect_score');
      if (lettersRevealed <= 1) await unlockAchievement('first_letter');
      if (lettersRevealed <= 2) await unlockAchievement('second_letter');
    }

    await _checkTheOne(itemResults);
  }

  Future<void> _checkTheOne(List<Map> currentItemResults) async {
    final allResults = <Map>[];
    for (final run in getRuns()) {
      final results = List<Map>.from(run['itemResults'] as List? ?? []);
      allResults.addAll(results);
    }
    allResults.addAll(currentItemResults);

    int consecutive = 0;
    for (final result in allResults) {
      if ((result['score'] as int? ?? 0) >= 1000) {
        consecutive++;
        if (consecutive >= 5) {
          await unlockAchievement('the_one');
          return;
        }
      } else {
        consecutive = 0;
      }
    }
  }

  // Player Infos
  String getPlayerName() {
    return Hive.box('stats').get('playerName', defaultValue: '') as String;
  }

  Future<void> setPlayerName(String name) async {
    await Hive.box('stats').put('playerName', name);
  }
}