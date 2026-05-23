import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/ebi_text_field.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

/// Page de connexion : email + password + lien forgot + lien register.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _showPwd = false;
  Map<String, List<String>> _errors = {};
  String? _globalError;

  Future<void> _submit() async {
    setState(() {
      _errors = {};
      _globalError = null;
      _loading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).login(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
      );
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      setState(() {
        _errors = e.fields;
        if (e.fields.isEmpty) _globalError = e.message;
      });
    } catch (_) {
      setState(() => _globalError = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo + titre
                  Container(
                    width: 72, height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: EbiColors.bluePale,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenue',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connectez-vous pour suivre vos colis.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 28),

                  // Form
                  EbiTextField(
                    label: 'Email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    required: true,
                    error: _errors['email']?.first,
                  ),
                  const SizedBox(height: 16),
                  EbiTextField(
                    label: 'Mot de passe',
                    controller: _pwdCtrl,
                    obscure: !_showPwd,
                    textInputAction: TextInputAction.done,
                    required: true,
                    error: _errors['password']?.first,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _showPwd = !_showPwd),
                      color: EbiColors.ink3,
                    ),
                  ),

                  // Forgot link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/auth/forgot-password'),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),

                  if (_globalError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EbiColors.dangerPale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _globalError!,
                        style: const TextStyle(color: EbiColors.danger, fontSize: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Submit
                  EbiButton(
                    label: 'Se connecter',
                    loading: _loading,
                    block: true,
                    onPressed: _submit,
                  ),

                  const SizedBox(height: 24),

                  // Divider + register
                  Row(children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OU', style: TextStyle(fontSize: 11, color: EbiColors.ink3)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),

                  EbiButton(
                    label: 'Créer un compte',
                    variant: EbiButtonVariant.secondary,
                    block: true,
                    onPressed: () => context.push('/auth/register'),
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
