// lib/core/l10n/app_strings.dart

class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    // Home
    'video_games': {'fr': 'Jeux vidéo', 'en': 'Video games'},
    'movies': {'fr': 'Films', 'en': 'Movies'},
    'flags': {'fr': 'Drapeaux', 'en': 'Flags'},
    'stats_achievements': {
      'fr': 'Stats & Succès',
      'en': 'Stats & Achievements',
    },
    'solo': {'fr': 'Solo', 'en': 'Solo'},
    'challenge_friend': {
      'fr': '10 drapeaux · Défier un ami',
      'en': '10 flags · Challenge a friend',
    },
    'solo_ranked': {'fr': '10 drapeaux · Classé', 'en': '10 flags · Ranked'},
    'multiplayer': {'fr': 'Multijoueur', 'en': 'Multiplayer'},
    'multiplayer_subtitle': {
      'fr': 'Créer ou rejoindre une room',
      'en': 'Create or join a room',
    },

    // Mode sheet
    'choose_mode': {'fr': 'Choisis ton mode', 'en': 'Choose your mode'},
    'quick': {'fr': 'Rapide', 'en': 'Quick'},
    'full': {'fr': 'Complet', 'en': 'Full'},
    'quick_hard': {'fr': 'Rapide Hard', 'en': 'Quick Hard'},
    'full_hard': {'fr': 'Complet Hard', 'en': 'Full Hard'},
    'items_5': {'fr': '5 items', 'en': '5 items'},
    'items_10': {'fr': '10 items', 'en': '10 items'},
    'fast_session': {
      'fr': 'Session rapide\n~2 minutes',
      'en': 'Fast session\n~2 minutes',
    },
    'full_run': {
      'fr': 'Partie complète\n~4 minutes',
      'en': 'Full run\n~4 minutes',
    },
    'one_mistake': {
      'fr': 'Une erreur\net c\'est fini',
      'en': 'One mistake\nand it\'s over',
    },
    'mode_subtitle': {
      'fr': 'Rapide · Complet · Hardcore',
      'en': 'Quick · Full · Hardcore',
    },
    'mode_subtitle_compact': {'fr': 'Rapide · Complet', 'en': 'Quick · Full'},
    'solo_ranked_compact': {'fr': 'Classé', 'en': 'Ranked'},
    'space': {'fr': 'Espace', 'en': 'Space'},
    'gemstones': {'fr': 'Gemmes', 'en': 'Gemstones'},
    'gemstones_subtitle_compact': {
      'fr': 'Pierres précieuses',
      'en': 'Precious stones',
    },
    'coming_soon': {'fr': 'Bientôt', 'en': 'Soon'},
    'space_subtitle_compact': {
      'fr': 'Distances planétaires',
      'en': 'Planet distances',
    },
    'space_distance_prompt': {
      'fr': 'Distance moyenne entre ces planètes',
      'en': 'Average distance between these planets',
    },
    'space_estimate': {'fr': 'Estimation', 'en': 'Estimate'},
    'space_real_distance': {'fr': 'Distance réelle', 'en': 'Real distance'},
    'space_difference': {'fr': 'Écart', 'en': 'Difference'},
    'space_avg_error': {'fr': 'Écart moy.', 'en': 'Avg error'},
    'space_validate': {'fr': 'Valider', 'en': 'Submit'},
    'space_next': {'fr': 'Manche suivante', 'en': 'Next round'},
    'space_results': {'fr': 'Résultats', 'en': 'Results'},
    'space_finished': {
      'fr': 'Exploration terminée',
      'en': 'Exploration complete',
    },
    'space_rounds': {'fr': 'manches', 'en': 'rounds'},

    // Game screen
    'hardcore': {'fr': 'HARDCORE', 'en': 'HARDCORE'},
    'guess_title': {'fr': 'Devinez le titre...', 'en': 'Guess the title...'},
    'hint_label': {
      'fr': 'Indice  ·  année + mot-clé  (score ÷2)',
      'en': 'Hint  ·  year + keyword  (score ÷2)',
    },
    'found': {'fr': 'Trouvé !', 'en': 'Found!'},
    'missed': {'fr': 'Raté !', 'en': 'Missed!'},
    'next': {'fr': 'Suivant', 'en': 'Next'},
    'score': {'fr': 'Score', 'en': 'Score'},
    'time': {'fr': 'Temps', 'en': 'Time'},
    'game_label': {'fr': 'Jeu', 'en': 'Game'},
    'film_label': {'fr': 'Film', 'en': 'Film'},

    // Run mode labels
    'quick_normal': {'fr': 'Rapide — Normal', 'en': 'Quick — Normal'},
    'quick_hardcore': {'fr': 'Rapide — Hardcore', 'en': 'Quick — Hardcore'},
    'full_normal': {'fr': 'Complet — Normal', 'en': 'Full — Normal'},
    'full_hardcore': {'fr': 'Complet — Hardcore', 'en': 'Full — Hardcore'},

    // Results screen
    'perfect': {'fr': 'Parfait !', 'en': 'Perfect!'},
    'great_job': {'fr': 'Bien joué !', 'en': 'Great job!'},
    'good_effort': {'fr': 'Pas mal !', 'en': 'Good effort!'},
    'keep_practicing': {'fr': 'Continue !', 'en': 'Keep practicing!'},
    'game_over': {'fr': 'Partie terminée !', 'en': 'Game over!'},
    'found_label': {'fr': 'Trouvés', 'en': 'Found'},
    'breakdown': {'fr': 'Détail', 'en': 'Breakdown'},
    'avg_time': {'fr': 'Temps moy.', 'en': 'Avg time'},
    'correct': {'fr': 'Correct', 'en': 'Correct'},
    'accuracy': {'fr': 'Précision', 'en': 'Accuracy'},
    'play_again': {'fr': 'Rejouer', 'en': 'Play again'},
    'share_result': {'fr': 'Partager', 'en': 'Share result'},
    'home': {'fr': 'Accueil', 'en': 'Home'},

    // Share messages
    'result_copied': {
      'fr': 'Résultat copié !',
      'en': 'Result copied to clipboard!',
    },
    'share_guess': {
      'fr':
          'Void Guess · {mode} · {found}/{total} trouvés · {score} pts ! Tu fais mieux ?',
      'en':
          'Void Guess · {mode} · {found}/{total} found · {score} pts! Can you do better?',
    },
    'share_flags': {
      'fr':
          'Void Flags — {correct}/{total} correct · {score} pts ! Tu fais mieux ?',
      'en':
          'Void Flags — {correct}/{total} correct · {score} pts! Can you do better?',
    },

    // Duel
    'create_room': {'fr': 'Créer une room', 'en': 'Create room'},
    'join_room': {'fr': 'Rejoindre', 'en': 'Join room'},
    'or': {'fr': 'ou', 'en': 'or'},
    'room_code': {'fr': 'Code de la room', 'en': 'Room code'},
    'tap_to_copy': {'fr': 'Appuyer pour copier', 'en': 'Tap to copy'},
    'code_copied': {'fr': 'Code copié !', 'en': 'Code copied!'},
    'waiting_opponent': {
      'fr': 'En attente d\'un adversaire...',
      'en': 'Waiting for opponent...',
    },
    'waiting_finish': {
      'fr': 'En attente de l\'adversaire...',
      'en': 'Waiting for opponent to finish...',
    },
    'ready': {'fr': 'Prêt', 'en': 'Ready'},
    'ready_done': {'fr': 'Prêt !', 'en': 'Ready!'},
    'leave': {'fr': '← Quitter', 'en': '← Leave'},
    'back': {'fr': '← Retour', 'en': '← Back'},
    'you': {'fr': '(vous)', 'en': '(you)'},
    'you_win': {'fr': 'Victoire !', 'en': 'You win!'},
    'you_lose': {'fr': 'Défaite !', 'en': 'You lose!'},
    'draw': {'fr': 'Égalité !', 'en': 'Draw!'},
    'duel_flags': {'fr': '1v1 Drapeaux', 'en': '1v1 Flags'},
    'room_not_found': {
      'fr': 'Room introuvable ou pleine',
      'en': 'Room not found or full',
    },
    'enter_code': {'fr': 'Entrez un code', 'en': 'Enter a room code'},
    'joining': {'fr': 'Connexion...', 'en': 'Joining...'},
    'lobby': {'fr': 'Lobby', 'en': 'Lobby'},
    'host_selects_game': {
      'fr': 'L\'hôte choisit le jeu',
      'en': 'The host chooses the game',
    },
    'selected_game': {'fr': 'Jeu sélectionné', 'en': 'Selected game'},
    'available_now': {'fr': 'Disponible maintenant', 'en': 'Available now'},
    'host_only_selection': {
      'fr': 'Seul l\'hôte peut changer la sélection',
      'en': 'Only the host can change the selection',
    },

    // Name dialog
    'choose_name': {'fr': 'Choisis un pseudo', 'en': 'Choose a name'},
    'shown_to_opponents': {
      'fr': 'Visible par tes adversaires',
      'en': 'This will be shown to opponents',
    },
    'enter_name': {'fr': 'Entre ton pseudo', 'en': 'Enter your name'},
    'continue_btn': {'fr': 'Continuer', 'en': 'Continue'},

    // Stats screen
    'stats_label': {'fr': 'Stats', 'en': 'Stats'},
    'achievements_label': {'fr': 'Succès', 'en': 'Achievements'},
    'best_run': {'fr': 'Meilleure partie', 'en': 'Best run'},
    'no_runs': {'fr': 'Aucune partie jouée.', 'en': 'No runs completed yet.'},
    'global': {'fr': 'Global', 'en': 'Global'},
    'runs_played': {'fr': 'Parties jouées', 'en': 'Runs played'},
    'success_rate': {'fr': 'Taux de réussite', 'en': 'Success rate'},
    'best_score': {'fr': 'Meilleur score', 'en': 'Best score'},
    'best_avg_time': {'fr': 'Meilleur temps moy.', 'en': 'Best avg time'},
    'reset_rank': {'fr': 'Réinitialiser le rang', 'en': 'Reset rank'},
    'reset_rank_title': {'fr': 'Réinitialiser le rang ?', 'en': 'Reset rank?'},
    'reset_rank_desc': {
      'fr':
          'Ton rang et tes VP seront réinitialisés à Void 0. Cette action est irréversible.',
      'en': 'Your rank and VP will be reset to Void 0. This cannot be undone.',
    },
    'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
    'reset': {'fr': 'Réinitialiser', 'en': 'Reset'},
    'unlocked': {'fr': 'Débloqué', 'en': 'Unlocked'},
    'locked': {'fr': 'Verrouillé', 'en': 'Locked'},

    'cat_speed': {'fr': 'Vitesse', 'en': 'Speed'},
    'cat_precision': {'fr': 'Précision', 'en': 'Precision'},
    'cat_runs': {'fr': 'Parties', 'en': 'Runs'},
    'cat_score': {'fr': 'Score', 'en': 'Score'},
    'cat_categories': {'fr': 'Catégories', 'en': 'Categories'},
    'cat_guess': {'fr': 'Titres', 'en': 'Titles'},
    'cat_flags': {'fr': 'Drapeaux', 'en': 'Flags'},
    'cat_space': {'fr': 'Espace', 'en': 'Space'},
    'cat_secret': {'fr': 'Secret', 'en': 'Secret'},
  };

  static String get(String key, String locale) {
    return _strings[key]?[locale] ?? _strings[key]?['en'] ?? key;
  }

  // Helper pour les strings avec paramètres
  static String format(String key, String locale, Map<String, String> params) {
    var result = get(key, locale);
    params.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    return result;
  }
}
