import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/config/env.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/colors.dart';
import '../auth/presentation/auth_controller.dart';

/// Écran de démarrage animé Flutter affiché au-dessus du splash natif.
/// Effectue les checks (token, onboarding) puis route vers la bonne page.
///
/// Branding : logo centré sur fond gradient bleu EBI, animation fade+scale,
/// barre de chargement discrète en bas. Aligné sur l'identité visuelle web.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Statut bar transparente sur le splash (full immersive).
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut),
    );

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _textCtrl.forward());

    // Routage final après l'animation + checks
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  Future<void> _decideNextRoute() async {
    // Le splash sert à masquer le temps de chargement réel (bootstrap réseau) :
    // on garde juste un court minimum pour que l'animation ne « flashe » pas,
    // puis on route dès que le chargement est terminé.
    final minDelay = Future.delayed(const Duration(milliseconds: 500));

    final prefs = ref.read(sharedPrefsProvider);
    final hasSeenOnboarding = prefs.getBool(Env.storageOnboardingSeen) ?? false;

    // Restaure la session + récupère /me, mais sans bloquer le démarrage si le
    // réseau est lent : au-delà de 6s on continue (le routing renverra au login).
    try {
      await ref.read(authControllerProvider.notifier).bootstrap()
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Timeout / erreur réseau : on poursuit avec l'état courant.
    }
    final auth = ref.read(authControllerProvider);

    await minDelay;
    if (!mounted) return;

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
    } else if (auth is AuthAuthenticated) {
      // TEMPORAIRE : vérification email désactivée (pas de mail pro configuré).
      // À réactiver : if (!auth.user.emailVerified) context.go('/auth/verify-email');
      context.go('/home');
    } else {
      context.go('/auth/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // width/height infinity : sans ça, le Container se dimensionne sur son
        // contenu (logo + texte) et n'occupe qu'une partie de l'écran sur certains
        // appareils — d'où le fond « moitié bleue / moitié blanche ».
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [EbiColors.blue, EbiColors.blueDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo dans un cercle blanc qui pulse doucement
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: EbiColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _textFade,
                child: Text(
                  'EBI Logistics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: EbiColors.white, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Camion de livraison animé (Lottie) — chargement thématique.
              FadeTransition(
                opacity: _textFade,
                child: Lottie.asset(
                  'assets/lottie/splash-truck.json',
                  width: 180, height: 120, fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
