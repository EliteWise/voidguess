import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/hive_service.dart';

class ResultsScreen extends StatefulWidget {
  final int score;
  final int timeSeconds;
  final String itemName;
  final bool usedHint;
  final String category;
  final bool isLost;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.timeSeconds,
    required this.itemName,
    required this.usedHint,
    required this.category,
    required this.isLost
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    _saveStats();
  }

  Future<void> _saveStats() async {
    await HiveService().saveStats(
      score: widget.score,
      timeSeconds: widget.timeSeconds,
      usedHint: widget.usedHint,
      category: widget.category,
    );
  }

  void _share() {
    final hint = widget.usedHint ? ' (avec indice)' : '';
    Share.share(
      'VoidGuess — j\'ai deviné "${widget.itemName}" en ${widget.timeSeconds}s$hint avec un score de ${widget.score} pts ! Peux-tu faire mieux ?',
    );
  }

  String get _scoreLabel {
    if (widget.isLost) return 'Perdu !';
    if (widget.score >= 800) return 'Excellent !';
    if (widget.score >= 400) return 'Bien joué !';
    return 'Pas mal...';
  }

  Color get _scoreColor {
    if (widget.isLost) return AppTheme.wrong;
    if (widget.score >= 800) return AppTheme.correct;
    if (widget.score >= 400) return AppTheme.primary;
    return AppTheme.hint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                _scoreLabel,
                style: TextStyle(
                  color: _scoreColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.itemName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _StatRow(label: 'Score', value: '${widget.score} pts', color: _scoreColor),
              const SizedBox(height: 12),
              _StatRow(label: 'Temps', value: '${widget.timeSeconds}s'),
              const SizedBox(height: 12),
              _StatRow(
                label: 'Indice utilisé',
                value: widget.usedHint ? 'Oui' : 'Non',
                color: widget.usedHint ? AppTheme.hint : AppTheme.correct,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/game?category=${widget.category}'),
                child: const Text('Rejouer'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _share,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                ),
                child: const Text('Partager'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text(
                  'Accueil',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}