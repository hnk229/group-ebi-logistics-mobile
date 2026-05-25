import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'cargo_picker.dart';

/// Choix du cargo après l'inscription : l'utilisateur sélectionne le partenaire
/// auprès duquel il expédie ses colis. Accessible depuis l'accueil tant qu'aucun
/// cargo n'est défini.
class ChooseCargoPage extends ConsumerStatefulWidget {
  const ChooseCargoPage({super.key});

  @override
  ConsumerState<ChooseCargoPage> createState() => _ChooseCargoPageState();
}

class _ChooseCargoPageState extends ConsumerState<ChooseCargoPage> {
  int? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pré-sélectionne le cargo actuel (cas changement de cargo).
    _selected = ref.read(currentUserProvider)?.cargo?.id;
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).chooseCargo(_selected!);
      await ref.read(authControllerProvider.notifier).refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargo enregistré.'), backgroundColor: EbiColors.success),
      );
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e)), backgroundColor: EbiColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Choisir mon cargo'),
        backgroundColor: EbiColors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Sélectionnez le cargo auprès duquel vous expédiez vos colis. '
              'Tapez sur un cargo pour voir ses tarifs et délais avant de choisir.',
              style: TextStyle(fontSize: 13, color: EbiColors.ink2, height: 1.5),
            ),
            const SizedBox(height: 16),
            CargoPicker(
              label: 'Cargos disponibles',
              value: _selected,
              onChanged: (c) => setState(() => _selected = c?.id),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: EbiColors.white,
          border: Border(top: BorderSide(color: EbiColors.border)),
        ),
        child: FilledButton(
          onPressed: (_selected == null || _saving) ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: EbiColors.blue,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(_saving ? 'Enregistrement…' : 'Confirmer ce cargo'),
        ),
      ),
    );
  }
}
