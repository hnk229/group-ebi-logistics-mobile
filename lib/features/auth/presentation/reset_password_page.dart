import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/ebi_text_field.dart';
import '../data/auth_repository.dart';

/// Réinitialisation du mot de passe.
/// Token + email reçus via deep link `ebilogistics://reset-password?token=…&email=…`
/// ou en query param `/auth/reset-password?token=…&email=…`.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.token, this.email});
  final String? token;
  final String? email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tokenCtrl;
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  bool _success = false;
  Map<String, List<String>> _errors = {};
  String? _globalError;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email ?? '');
    _tokenCtrl = TextEditingController(text: widget.token ?? '');
  }

  Future<void> _submit() async {
    if (_pwdCtrl.text != _pwd2Ctrl.text) {
      setState(() => _errors = {'password_confirmation': ['Les mots de passe ne correspondent pas.']});
      return;
    }
    setState(() {
      _errors = {};
      _globalError = null;
      _loading = true;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
        email: _emailCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
        password: _pwdCtrl.text,
      );
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/auth/login');
    } on AuthException catch (e) {
      setState(() {
        _errors = e.fields;
        if (e.fields.isEmpty) _globalError = e.message;
      });
    } catch (_) {
      setState(() => _globalError = 'Le lien est invalide ou expiré.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_success)
                  _successCard(context)
                else
                  _formCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(
            color: EbiColors.bluePale, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, size: 32, color: EbiColors.blue),
        ),
        const SizedBox(height: 16),
        Text(
          'Choisissez un nouveau mot de passe',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),

        EbiTextField(
          label: 'Email', controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false, required: true,
          error: _errors['email']?.first,
        ),
        const SizedBox(height: 14),
        EbiTextField(
          label: 'Nouveau mot de passe', controller: _pwdCtrl,
          obscure: !_showPwd, required: true,
          helper: '8 caractères minimum, lettres + chiffres.',
          error: _errors['password']?.first,
          suffix: IconButton(
            icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility, size: 18),
            onPressed: () => setState(() => _showPwd = !_showPwd),
            color: EbiColors.ink3,
          ),
        ),
        const SizedBox(height: 14),
        EbiTextField(
          label: 'Confirmer', controller: _pwd2Ctrl,
          obscure: !_showPwd, required: true,
          error: _errors['password_confirmation']?.first,
        ),

        if (widget.token == null) ...[
          const SizedBox(height: 14),
          EbiTextField(
            label: 'Code reçu par email', controller: _tokenCtrl,
            required: true, error: _errors['token']?.first,
            helper: 'Collez ici le code reçu dans l\'email.',
          ),
        ],

        if (_globalError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EbiColors.dangerPale,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_globalError!, style: const TextStyle(color: EbiColors.danger, fontSize: 12)),
          ),
        ],

        const SizedBox(height: 16),
        EbiButton(
          label: 'Réinitialiser',
          loading: _loading, block: true,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _successCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: EbiColors.successPale, shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 48, color: EbiColors.success),
        ),
        const SizedBox(height: 16),
        Text(
          'Mot de passe réinitialisé',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vous allez être redirigé vers la connexion…',
          style: TextStyle(fontSize: 13, color: EbiColors.ink3),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
