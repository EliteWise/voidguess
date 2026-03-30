import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const Text(
                'VOID',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'GUESSR',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                onPressed: () => context.go('/game?category=game'),
                child: const Text('Jeux vidéo'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/game?category=movie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                ),
                child: const Text('Films'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/achievements'),
                child: const Text(
                  'Succès',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}