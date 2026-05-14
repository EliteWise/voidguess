# Void Guess - Bonnes pratiques de développement

Ce document sert de guide de travail pour garder le projet propre, stable et facile à faire évoluer. L'objectif n'est pas de tout rigidifier, mais d'avoir des réflexes professionnels constants.

## Principes

- Privilégier les changements petits, ciblés et faciles à vérifier.
- Respecter les patterns déjà présents dans le projet avant d'ajouter une nouvelle abstraction.
- Séparer clairement la logique de jeu, l'affichage, le stockage local et la navigation.
- Ne pas mélanger les refactors avec les features, sauf si le refactor est nécessaire pour livrer la feature proprement.
- Tester la logique critique, surtout les providers, scoring, résultats, achievements et services Hive.

## Structure du projet

Les features doivent rester autonomes autant que possible:

```text
lib/features/<feature_name>/
  models/
  providers/
  screens/
  widgets/
```

Exemples:

- `flag_game` contient la logique et les écrans du jeu drapeaux.
- `space_game` contient la logique et les écrans du jeu espace.
- `gemstone_game` contient la logique et les écrans du jeu gemmes.

Évite de mettre de la logique métier directement dans `home_screen.dart`, `app_router.dart` ou les widgets globaux.

## Providers et état

Pour un mini-jeu:

- Créer un provider dédié dans `features/<game>/providers/`.
- Garder un `State` immutable avec `copyWith`.
- Garder le scoring, la sélection des options, le timer logique et la progression dans le notifier.
- L'écran doit surtout gérer l'affichage, les timers UI et la navigation.

Un bon provider de jeu expose au minimum:

- l'item courant
- les options
- l'index de manche
- le timer
- la phase (`playing`, `feedback`, etc.)
- les résultats
- le score total

## Écrans et layout

Pour les écrans de jeu fixes, préférer:

```dart
Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(...);
        },
      ),
    ),
  ),
)
```

Évite `SingleChildScrollView + IntrinsicHeight + Spacer`, car ce combo peut provoquer des problèmes de layout ou de semantics.

Utiliser `SingleChildScrollView` pour:

- les pages de résultats
- les stats
- les listes longues
- les contenus qui peuvent dépasser selon la taille d'écran

Utiliser `Column` fixe pour:

- les jeux avec une grille contrôlée
- les écrans de quiz
- les interfaces où le contenu doit rester stable

## Assets

Quand tu ajoutes des images:

1. Les placer dans un dossier clair: `assets/planets/`, `assets/gemstones/`, etc.
2. Déclarer le dossier dans `pubspec.yaml`.
3. Utiliser des noms de fichiers simples, en minuscules, sans espaces.
4. Garder une correspondance explicite dans un modèle ou une liste typée.

Exemple:

```dart
const Gemstone(
  id: 1,
  nameFr: 'Améthyste',
  nameEn: 'Amethyst',
  assetPath: 'assets/gemstones/amethyst.png',
);
```

## Résultats et achievements

Chaque jeu peut avoir sa propre page de résultats si son modèle de scoring ou son affichage est différent.

Créer une page indépendante quand:

- le détail par manche n'a pas la même forme
- le score n'a pas la même signification
- les stats affichées sont spécifiques au jeu

Réutiliser une page existante seulement si les données ont vraiment la même structure.

Pour les achievements:

- Déclarer l'achievement dans `assets/data/achievements.json`.
- Ajouter la logique de déblocage dans `HiveService`.
- Déclencher le check depuis la page de résultats du jeu.
- Ajouter un test si la condition est importante.

## Hive et stockage local

Les clés Hive doivent rester explicites:

- `runs` pour les runs titres
- `flagRuns` pour les runs drapeaux
- `spaceRuns` pour les runs espace
- éviter les noms vagues comme `data`, `items`, `history2`

Quand une feature stocke des données:

- stocker uniquement ce qui est utile aux stats, achievements ou historique
- garder des maps simples et stables
- éviter de stocker directement des objets complexes non sérialisés

## Routing

Ajouter une route par écran de jeu et par écran de résultats:

```dart
/gemstone_game
/gemstone_results
```

Dans `app_router.dart`, garder le parsing de `state.extra` défensif:

```dart
final extra = state.extra as Map<String, dynamic>? ?? {};
```

Cela évite les crashs si une page est ouverte sans données.

## Localisation

Tous les textes affichés dans l'UI doivent passer par `AppStrings` et `ref.tr(...)`, sauf:

- noms propres
- labels temporaires internes
- valeurs dynamiques

Quand tu ajoutes une clé:

- ajouter `fr`
- ajouter `en`
- utiliser un nom clair, par exemple `gemstones_subtitle_compact`

## Tests

Tester en priorité:

- providers de jeu
- scoring
- transitions de phase
- achievements
- services Hive

Les tests widget peuvent être utiles, mais attention aux dépendances UI comme `google_fonts` qui peuvent rendre les tests instables offline. Pour la logique pure, préférer un test provider/service.

Commandes utiles:

```bash
flutter analyze
flutter test
flutter test test/features/gemstone_game/gemstone_game_provider_test.dart
```

## Analyse et formatage

Avant de considérer une feature terminée:

```bash
dart format lib test
flutter analyze
flutter test
```

Si `flutter analyze` remonte des warnings déjà existants hors périmètre, ne pas les mélanger à la feature. Les traiter dans un commit/refactor séparé.

## Git

Avant de commencer:

```bash
git status --short
```

Pendant le travail:

- ne jamais revert des changements que tu n'as pas faits
- éviter les gros commits fourre-tout
- grouper par intention: feature, fix, refactor, test

Exemples de commits propres:

```text
feat: add gemstone guessing game
feat: add space achievements
fix: avoid scroll intrinsic layout in gemstone game
test: cover gemstone provider scoring
```

## Checklist feature

Avant de dire qu'une feature est prête:

- L'écran est branché dans le routeur.
- L'accès depuis l'accueil fonctionne.
- Les assets sont déclarés dans `pubspec.yaml`.
- Les textes UI sont localisés.
- Le provider ou service critique est testé.
- `flutter analyze` ne montre pas d'erreur liée à la feature.
- Le layout a été pensé pour petite hauteur et mobile.
- La page de résultats existe si le jeu produit une run complète.

## Dette technique à surveiller

Points à améliorer progressivement:

- Nettoyer les warnings existants `withOpacity` vers `withValues`.
- Typage plus strict dans certains écrans existants.
- Factoriser certains widgets de résultats si trois pages commencent à vraiment diverger.
- Éviter les imports directs non déclarés dans `pubspec.yaml`.
- Ajouter des tests aux achievements existants, pas seulement aux nouveaux.

## Règle générale

Une bonne feature Void Guess doit être:

- jouable sans explication
- stable sur mobile
- cohérente avec le style existant
- isolée dans sa feature
- testée au moins sur sa logique principale
- facile à supprimer ou modifier sans casser les autres jeux
