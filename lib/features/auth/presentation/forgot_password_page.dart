import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/ebi_text_field.dart';
import '../data/auth_repository.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                    color: EbiColors.bluePale, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline, size: 32, color: EbiColors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  _sent ? 'Email envoyé' : 'Réinitialisez votre mot de passe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (_sent)
                  Text(
                    'Si cette adresse existe, un lien de réinitialisation vient d\'être envoyé. Vérifiez votre boîte de réception et vos spams.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Text(
                    'Saisissez votre email pour recevoir un lien sécurisé.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 24),

                if (!_sent) ...[
                  EbiTextField(
                    label: 'Email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    required: true,
                    autofocus: true,
                    error: _error,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  EbiButton(
                    label: 'Envoyer le lien',
                    loading: _loading,
                    block: true,
                    onPressed: _submit,
                  ),
                ] else ...[
                  EbiButton(
                    label: 'Retour à la connexion',
                    block: true,
                    onPressed: () => context.go('/auth/login'),
                  ),
                ],

                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
