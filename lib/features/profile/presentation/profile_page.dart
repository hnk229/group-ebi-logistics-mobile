import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/ebi_text_field.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  final _curPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _newPwd2Ctrl = TextEditingController();

  bool _saving = false;
  bool _changingPwd = false;
  String? _msg;
  bool _msgError = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider);
    if (u != null) {
      _nameCtrl.text = u.name;
      _emailCtrl.text = u.email;
      _phoneCtrl.text = u.phone ?? '';
      _villeCtrl.text = u.ville ?? '';
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _msg = null; });
    final api = ref.read(apiClientProvider);
    try {
      await api.patch('/api/profile', data: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
      });
      await ref.read(authControllerProvider.notifier).refreshMe();
      setState(() {
        _msg = 'Profil mis à jour.';
        _msgError = false;
      });
    } catch (e) {
      setState(() {
        _msg = 'Erreur de mise à jour.';
        _msgError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePwd() async {
    if (_newPwdCtrl.text != _newPwd2Ctrl.text) {
      setState(() { _msg = 'Les mots de passe ne correspondent pas.'; _msgError = true; });
      return;
    }
    setState(() { _changingPwd = true; _msg = null; });
    final api = ref.read(apiClientProvider);
    try {
      await api.post('/api/profile/password', data: {
        'current_password': _curPwdCtrl.text,
        'password': _newPwdCtrl.text,
        'password_confirmation': _newPwd2Ctrl.text,
      });
      _curPwdCtrl.clear(); _newPwdCtrl.clear(); _newPwd2Ctrl.clear();
      setState(() { _msg = 'Mot de passe modifié.'; _msgError = false; });
    } catch (e) {
      setState(() { _msg = 'Mot de passe actuel incorrect ou nouveau invalide.'; _msgError = true; });
    } finally {
      if (mounted) setState(() => _changingPwd = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _villeCtrl.dispose();
    _curPwdCtrl.dispose(); _newPwdCtrl.dispose(); _newPwd2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: EbiColors.white,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Informations personnelles',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            EbiTextField(label: 'Nom complet', controller: _nameCtrl, required: true),
            const SizedBox(height: 12),
            EbiTextField(label: 'Email', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress, required: true),
            const SizedBox(height: 12),
            EbiTextField(label: 'Téléphone', controller: _phoneCtrl,
              keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            EbiTextField(label: 'Ville', controller: _villeCtrl),
            const SizedBox(height: 14),
            EbiButton(label: 'Enregistrer', loading: _saving, block: true, onPressed: _save),
          ]),
        )),

        const SizedBox(height: 16),

        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Changer le mot de passe',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            EbiTextField(label: 'Mot de passe actuel', controller: _curPwdCtrl, obscure: true, required: true),
            const SizedBox(height: 12),
            EbiTextField(label: 'Nouveau mot de passe', controller: _newPwdCtrl, obscure: true, required: true,
              helper: '8 caractères minimum, lettres + chiffres.'),
            const SizedBox(height: 12),
            EbiTextField(label: 'Confirmer', controller: _newPwd2Ctrl, obscure: true, required: true),
            const SizedBox(height: 14),
            EbiButton(label: 'Changer', loading: _changingPwd, block: true, onPressed: _changePwd),
          ]),
        )),

        if (_msg != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _msgError ? EbiColors.dangerPale : EbiColors.successPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_msg!, style: TextStyle(
              color: _msgError ? EbiColors.danger : EbiColors.success, fontSize: 12,
            )),
          ),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}
