import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voidguess/core/l10n/app_strings.dart';
import 'package:voidguess/core/provider/locale_provider.dart';

// Utilisable dans les widgets (ConsumerWidget, ConsumerState)
extension L10nRef on WidgetRef {
  String tr(String key) => AppStrings.get(key, watch(localeProvider));
}

// Utilisable dans les providers et notifiers
extension L10nRead on Ref {
  String tr(String key) => AppStrings.get(key, read(localeProvider));
}