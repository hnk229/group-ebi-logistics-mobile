import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_user.dart';

/// État global d'auth : utilisateur courant + statut de chargement.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthGuest extends AuthState {
  const AuthGuest();
}

/// Notifier Riverpod 3 : login/register/logout + bootstrap au démarrage.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final ApiClient _api;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    _api = ref.read(apiClientProvider);
    return const AuthInitial();
  }

  /// Restaure le token + récupère le user. Appelé depuis SplashPage.
  Future<void> bootstrap() async {
    final token = await _api.restoreToken();
    if (token == null) {
      state = const AuthGuest();
      return;
    }
    final user = await _repo.me();
    if (user == null) {
      await _api.setToken(null);
      state = const AuthGuest();
    } else {
      state = AuthAuthenticated(user);
    }
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final res = await _repo.login(email: email, password: password);
    await _api.setToken(res.token);
    state = AuthAuthenticated(res.user);
    return res.user;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    int? cargoId,
    int? paysId,
    String? ville,
  }) async {
    final res = await _repo.register(
      name: name, email: email, password: password,
      phone: phone, cargoId: cargoId, paysId: paysId, ville: ville,
    );
    await _api.setToken(res.token);
    state = AuthAuthenticated(res.user);
    return res.user;
  }

  Future<void> logout() async {
    await _repo.logout();
    await _api.setToken(null);
    state = const AuthGuest();
  }

  Future<void> refreshMe() async {
    final user = await _repo.me();
    if (user != null) state = AuthAuthenticated(user);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Helper : user courant ou null.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final s = ref.watch(authControllerProvider);
  return s is AuthAuthenticated ? s.user : null;
});

/// Helper : booléen connecté.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider) is AuthAuthenticated;
});
