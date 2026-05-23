import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider singleton de SharedPreferences (à override dans main()).
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPrefsProvider dans main() avec SharedPreferences.getInstance()');
});
