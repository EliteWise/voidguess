import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final localeProvider = StateProvider<String>((ref) => 'fr'); // défaut FR