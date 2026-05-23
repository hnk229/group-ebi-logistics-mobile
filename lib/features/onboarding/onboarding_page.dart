import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/config/env.dart';
import '../../core/storage/prefs.dart';
import '../../core/theme/colors.dart';
import 'widgets/onboarding_illustration.dart';

/// Onboarding affiché 1 seule fois au tout premier démarrage.
/// 3 slides : bienvenue, suivi des colis, paiement sécurisé.
/// Le statut "vu" est stocké dans SharedPreferences sous Env.storageOnboardingSeen.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _currentIndex = 0;

  final _slides = const [
    _Slide(
      illustration: OnboardingIllustrationType.welcome,
      title: 'Bienvenue sur EBI Logistics',
      subtitle: 'Toute votre logistique Chine → Afrique dans votre poche.',
      description: 'Suivez vos achats sur AliExpress, Taobao, 1688 jusqu\'à leur livraison chez vous, en toute simplicité.',
    ),
    _Slide(
      illustration: OnboardingIllustrationType.tracking,
      title: 'Suivez vos colis en temps réel',
      subtitle: 'De l\'entrepôt chinois jusqu\'à votre porte.',
      description: 'Recevez une notification à chaque étape : reçu, payé, en transit, arrivé. Vos colis n\'auront plus de secrets.',
    ),
    _Slide(
      illustration: OnboardingIllustrationType.payment,
      title: 'Payez en Mobile Money',
      subtitle: 'MTN, Moov, Orange, Wave, Carte bancaire.',
      description: 'Réglez vos frais d\'envoi en quelques secondes avec votre opérateur préféré. 100 % sécurisé.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(Env.storageOnboardingSeen, true);
    if (!mounted) return;
    context.go('/auth/login');
  }

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: EbiColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header : bouton "Passer" en haut à droite
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Passer'),
                    ),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Footer : indicators + bouton CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _slides.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: EbiColors.blue,
                      dotColor: EbiColors.border,
                      dotHeight: 8, dotWidth: 8, spacing: 6,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Commencer' : 'Suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.description,
  });
  final OnboardingIllustrationType illustration;
  final String title;
  final String subtitle;
  final String description;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Expanded(
            flex: 5,
            child: Center(
              child: OnboardingIllustration(type: slide.illustration),
            ),
          ),

          // Texte
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  slide.subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: EbiColors.blue, fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  slide.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
