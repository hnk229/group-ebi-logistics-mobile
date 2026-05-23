import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'models/auth_user.dart';

/// Repository des appels API d'auth (login/register/forgot/reset/me/logout).
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// POST /api/auth/login → { user, token }
  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    final resp = await _api.post('/api/auth/login', data: {
      'email': email,
      'password': password,
      'device_name': 'mobile-app',
    });
    final data = resp.data as Map<String, dynamic>;
    if (resp.statusCode != 200) {
      throw _toException(data, resp.statusCode);
    }
    return (
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  /// POST /api/auth/register (rôle client par défaut)
  Future<({AuthUser user, String token})> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    int? cargoId,
    int? paysId,
    String? ville,
  }) async {
    final resp = await _api.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (cargoId != null) 'cargo_id': cargoId,
      if (paysId != null) 'pays_id': paysId,
      if (ville != null && ville.isNotEmpty) 'ville': ville,
      'locale': 'fr',
    });
    final data = resp.data as Map<String, dynamic>;
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw _toException(data, resp.statusCode);
    }
    return (
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  /// POST /api/auth/password/forgot (toujours 200 anti-énumération)
  Future<void> forgotPassword(String email) async {
    final resp = await _api.post('/api/auth/password/forgot', data: {'email': email});
    if (resp.statusCode != 200) {
      throw _toException(resp.data as Map<String, dynamic>, resp.statusCode);
    }
  }

  /// POST /api/auth/password/reset
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    final resp = await _api.post('/api/auth/password/reset', data: {
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': password,
    });
    if (resp.statusCode != 200) {
      throw _toException(resp.data as Map<String, dynamic>, resp.statusCode);
    }
  }

  /// POST /api/auth/email/verification-notification (renvoyer le mail)
  Future<void> resendVerificationEmail() async {
    final resp = await _api.post('/api/auth/email/verification-notification');
    if (resp.statusCode != 200 && resp.statusCode != 202) {
      throw _toException(resp.data as Map<String, dynamic>, resp.statusCode);
    }
  }

  /// GET /api/auth/me → { user }
  Future<AuthUser?> me() async {
    try {
      final resp = await _api.get('/api/auth/me');
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/auth/logout (révoque le token courant côté serveur)
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // On ignore — la session locale est purgée quoi qu'il arrive.
    }
  }

  AuthException _toException(Map<String, dynamic> data, int? status) {
    final message = (data['message'] as String?) ?? 'Erreur';
    final errors = <String, List<String>>{};
    if (data['errors'] is Map) {
      (data['errors'] as Map).forEach((key, value) {
        if (value is List) {
          errors[key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
    }
    return AuthException(message: message, status: status, fields: errors);
  }
}

/// Exception métier d'auth — porte les erreurs de champ pour l'UI.
class AuthException implements Exception {
  AuthException({required this.message, this.status, this.fields = const {}});
  final String message;
  final int? status;
  final Map<String, List<String>> fields;

  @override
  String toString() => message;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
