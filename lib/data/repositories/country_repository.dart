import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/country.dart';

class CountryRepository {
  List<Country>? _cache;

  Future<List<Country>> getCountries() async {
    // Si on a déjà chargé les pays une fois, on retourne le cache
    // Evite de relire le fichier JSON à chaque appel
    if (_cache != null) return _cache!;

    // Lit le fichier JSON depuis les assets Flutter
    // rootBundle = accès aux fichiers dans assets/
    // loadString = lit le contenu comme une String
    final String json = await rootBundle.loadString('assets/data/countries.json');

    // Convertit la String JSON en List<dynamic> Dart
    // jsonDecode retourne un Object — on cast en List<dynamic>
    final List<dynamic> data = jsonDecode(json);

    // Transforme chaque Map<String, dynamic> en objet Country
    // via le factory Country.fromJson qu'on a défini dans le modèle
    // et stocke le résultat dans le cache
    _cache = data.map((e) => Country.fromJson(e)).toList();

    return _cache!;
  }

  // Retourne un pays random pour la question
  Future<Country> getRandomCountry({List<int>? excludeIds}) async {
    final countries = await getCountries();
    var pool = countries;

    // Exclut les pays déjà utilisés dans la run
    if (excludeIds != null && excludeIds.isNotEmpty) {
      pool = countries.where((c) => !excludeIds.contains(c.id)).toList();
    }

    pool.shuffle();
    return pool.first;
  }

  Future<List<Country>> getDistractors({
    required Country correct,   // le bon pays — à exclure des distracteurs
    required int count,         // combien de distracteurs on veut (5 dans notre cas)
    List<int>? excludeIds,      // pays déjà utilisés dans la run — optionnel
  }) async {
    final countries = await getCountries();

    // Filtre la liste complète pour garder seulement les pays valides
    var pool = countries.where((c) =>
    // Exclut le bon pays — pas logique d'avoir la bonne réponse en distracteur
    c.id != correct.id &&
        // Exclut les pays déjà vus dans la run si on en a une liste
        // Le ?? [] gère le cas où excludeIds est null
        (excludeIds == null || !excludeIds.contains(c.id))
    ).toList();

    // Mélange aléatoirement le pool
    pool.shuffle();

    // Prend les X premiers après le shuffle
    // take(5) sur une liste de 49 pays = 5 pays random
    return pool.take(count).toList();
  }

  // Retourne le bon pays + 5 distracteurs mélangés — les 6 options de la grille
  Future<List<Country>> getOptions({required Country correct}) async {
    final distractors = await getDistractors(
      correct: correct,
      count: 5,
    );

    final options = [correct, ...distractors];
    options.shuffle();
    return options;
  }
}