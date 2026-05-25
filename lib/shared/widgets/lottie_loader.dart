import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/colors.dart';

/// Loader animé (Lottie) réutilisable à la place de CircularProgressIndicator.
/// Usage : `const LottieLoader()` ou `LottieLoader(label: 'Chargement…')`.
class LottieLoader extends StatelessWidget {
  const LottieLoader({super.key, this.size = 72, this.label});
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset('assets/lottie/loader.json', width: size, height: size),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: const TextStyle(fontSize: 12, color: EbiColors.ink3)),
          ],
        ],
      ),
    );
  }
}
