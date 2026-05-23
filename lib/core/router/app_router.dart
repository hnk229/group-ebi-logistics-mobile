import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/address/presentation/address_page.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/email_verify_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/colis/presentation/add_colis_page.dart';
import '../../features/colis/presentation/colis_detail_page.dart';
import '../../features/colis/presentation/colis_list_page.dart';
import '../../features/home/home_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/profile/presentation/menu_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/splash/splash_page.dart';
import '../../shared/layouts/main_shell.dart';

/// Router go_router : splash → auth → main shell (4 onglets) + détails.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.matchedLocation;

      if (path == '/' || path == '/onboarding') return null;
      final isAuthRoute = path.startsWith('/auth');

      if (auth is AuthGuest) {
        return isAuthRoute ? null : '/auth/login';
      }
      if (auth is AuthAuthenticated) {
        if (!auth.user.emailVerified && path != '/auth/verify-email') {
          return '/auth/verify-email';
        }
        if (auth.user.emailVerified && isAuthRoute && path != '/auth/verify-email') {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      // Splash + onboarding sans shell
      GoRoute(path: '/', name: 'splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, __) => const OnboardingPage()),

      // Auth (sans shell)
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: '/auth/reset-password', builder: (_, s) => ResetPasswordPage(
        token: s.uri.queryParameters['token'],
        email: s.uri.queryParameters['email'],
      )),
      GoRoute(path: '/auth/verify-email', builder: (_, __) => const EmailVerifyPage()),

      // Espace authentifié — Shell avec bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/colis', builder: (_, __) => const ColisListPage()),
          GoRoute(path: '/address', builder: (_, __) => const AddressPage()),
          GoRoute(path: '/menu', builder: (_, __) => const MenuPage()),
        ],
      ),

      // Pages secondaires (hors shell — push)
      GoRoute(path: '/colis/new', builder: (_, __) => const AddColisPage()),
      GoRoute(path: '/colis/:id', builder: (_, s) =>
        ColisDetailPage(colisId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/chat', builder: (_, __) => const ChatPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
    ],
  );
});
