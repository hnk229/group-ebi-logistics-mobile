import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

/// Page affichée tant que l'email du user n'est pas vérifié.
/// Offre la possibilité de renvoyer l'email + vérification manuelle (refresh /me).
class EmailVerifyPage extends ConsumerStatefulWidget {
  const EmailVerifyPage({super.key});

  @override
  ConsumerState<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends ConsumerState<EmailVerifyPage> {
  bool _resending = false;
  bool _checking = false;
  String? _message;
  bool _isError = false;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
      _isError = false;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail();
      setState(() => _message = 'Email renvoyé. Vérifiez votre boîte de réception.');
    } catch (e) {
      setState(() {
        _isError = true;
        _message = 'Impossible de renvoyer l\'email.';
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _refresh() async {
    setState(() { _checking = true; _message = null; });
    await ref.read(authControllerProvider.notifier).refreshMe();
    final user = ref.read(currentUserProvider);
    if (user?.emailVerified ?? false) {
      if (mounted) context.go('/home');
    } else {
      setState(() {
        _isError = true;
        _message = 'Email non encore vérifié. Cliquez sur le lien reçu.';
      });
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                      color: EbiColors.warningPale, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_unread, size: 40, color: EbiColors.warning),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vérifiez votre email',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un lien de vérification a été envoyé à ${user?.email ?? "votre adresse"}. Cliquez dessus pour activer votre compte, puis revenez ici.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isError ? EbiColors.dangerPale : EbiColors.successPale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isError ? EbiColors.danger : EbiColors.success,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  EbiButton(
                    label: 'J\'ai vérifié, continuer',
                    loading: _checking,
                    block: true,
                    onPressed: _refresh,
                  ),
                  const SizedBox(height: 8),
                  EbiButton(
                    label: 'Renvoyer l\'email',
                    variant: EbiButtonVariant.secondary,
                    loading: _resending,
                    block: true,
                    onPressed: _resend,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go('/auth/login');
                    },
                    child: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
