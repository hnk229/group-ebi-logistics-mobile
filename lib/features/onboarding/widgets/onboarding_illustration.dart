import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

enum OnboardingIllustrationType { welcome, tracking, payment }

/// Illustrations vectorielles légères pour l'onboarding — pas d'asset externe.
/// Style flat, palette EBI, lisible sur tous écrans.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.type});
  final OnboardingIllustrationType type;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final size = c.maxHeight.clamp(180.0, 280.0);
        return SizedBox(
          width: size, height: size,
          child: switch (type) {
            OnboardingIllustrationType.welcome => const _WelcomeIllustration(),
            OnboardingIllustrationType.tracking => const _TrackingIllustration(),
            OnboardingIllustrationType.payment => const _PaymentIllustration(),
          },
        );
      },
    );
  }
}

/// Slide 1 : globe + chemin Chine ↔ Afrique
class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle de fond
        Container(
          width: 220, height: 220,
          decoration: const BoxDecoration(
            color: EbiColors.bluePale,
            shape: BoxShape.circle,
          ),
        ),
        // Globe stylisé
        Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            color: EbiColors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EbiColors.blue.withValues(alpha: 0.3),
                blurRadius: 30, offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.public, size: 100, color: EbiColors.white),
        ),
        // Petite carte "Chine"
        Positioned(
          top: 35, left: 30,
          child: _MiniCard(label: '中国', emoji: '📦'),
        ),
        // Petite carte "Afrique"
        Positioned(
          bottom: 35, right: 30,
          child: _MiniCard(label: 'Afrique', emoji: '🏠'),
        ),
      ],
    );
  }
}

/// Slide 2 : carte avec étapes tracking
class _TrackingIllustration extends StatelessWidget {
  const _TrackingIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EbiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EbiColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _TrackingStep(label: 'Reçu en Chine', done: true),
          _TrackingLine(active: true),
          _TrackingStep(label: 'Payé', done: true),
          _TrackingLine(active: true),
          _TrackingStep(label: 'En transit', done: true, isCurrent: true),
          _TrackingLine(active: false),
          _TrackingStep(label: 'Arrivé', done: false),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({required this.label, required this.done, this.isCurrent = false});
  final String label;
  final bool done;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: done ? EbiColors.blue : EbiColors.surface2,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: EbiColors.blue, width: 3)
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: EbiColors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: done ? EbiColors.ink : EbiColors.ink3,
          ),
        ),
      ],
    );
  }
}

class _TrackingLine extends StatelessWidget {
  const _TrackingLine({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Container(
        width: 2, height: 18,
        color: active ? EbiColors.blue : EbiColors.border,
      ),
    );
  }
}

/// Slide 3 : carte de paiement avec téléphone + carte bancaire
class _PaymentIllustration extends StatelessWidget {
  const _PaymentIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 240, height: 240,
          decoration: const BoxDecoration(
            color: EbiColors.bluePale,
            shape: BoxShape.circle,
          ),
        ),
        // Smartphone derrière
        Positioned(
          right: 30, top: 30,
          child: Container(
            width: 100, height: 170,
            decoration: BoxDecoration(
              color: EbiColors.ink,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EbiColors.ink3, width: 2),
            ),
            child: Center(
              child: Container(
                width: 80, height: 150,
                decoration: BoxDecoration(
                  color: EbiColors.successPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, color: EbiColors.success, size: 40),
                ),
              ),
            ),
          ),
        ),
        // Carte bancaire devant
        Positioned(
          left: 30, bottom: 40,
          child: Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 160, height: 100,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EbiColors.blue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: EbiColors.blue.withValues(alpha: 0.4),
                    blurRadius: 20, offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 26, height: 18, decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(3),
                  )),
                  const Text(
                    '•••• 4242',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.label, required this.emoji});
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EbiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EbiColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: EbiColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
