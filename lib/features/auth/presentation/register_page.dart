import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/ebi_text_field.dart';
import '../data/auth_repository.dart';
import '../data/public_refs_repository.dart';
import 'auth_controller.dart';

/// Page d'inscription client : nom, email, téléphone, mot de passe,
/// pays + ville (optionnels), cargo partenaire (optionnel — peut être choisi
/// plus tard depuis l'app).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  int? _selectedCargo;
  int? _selectedPays;
  bool _showPwd = false;
  bool _loading = false;
  bool _acceptTerms = false;
  Map<String, List<String>> _errors = {};
  String? _globalError;

  Future<void> _submit() async {
    if (!_acceptTerms) {
      setState(() => _globalError = 'Vous devez accepter les conditions d\'utilisation.');
      return;
    }
    setState(() {
      _errors = {};
      _globalError = null;
      _loading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
        phone: _phoneCtrl.text.trim(),
        cargoId: _selectedCargo,
        paysId: _selectedPays,
        ville: _villeCtrl.text.trim(),
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cargosAsync = ref.watch(cargosFutureProvider);
    final paysAsync = ref.watch(paysFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: EbiColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rejoignez EBI Logistics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commencez à recevoir vos colis Chine → Afrique.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                EbiTextField(
                  label: 'Nom complet', controller: _nameCtrl,
                  required: true, error: _errors['name']?.first,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                EbiTextField(
                  label: 'Email', controller: _emailCtrl,
                  required: true, error: _errors['email']?.first,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false, textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                EbiTextField(
                  label: 'Téléphone (WhatsApp)', controller: _phoneCtrl,
                  hint: '+228 90 00 00 01',
                  keyboardType: TextInputType.phone,
                  helper: 'Chiffres et indicatif uniquement.',
                  error: _errors['phone']?.first,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                EbiTextField(
                  label: 'Mot de passe', controller: _pwdCtrl,
                  obscure: !_showPwd, required: true,
                  error: _errors['password']?.first,
                  helper: '8 caractères minimum, lettres + chiffres.',
                  suffix: IconButton(
                    icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _showPwd = !_showPwd),
                    color: EbiColors.ink3,
                  ),
                ),

                const SizedBox(height: 20),
                const _SectionTitle('Votre destination (optionnel)'),
                const SizedBox(height: 12),

                // Pays
                paysAsync.when(
                  loading: () => const _LoadingTile('Chargement des pays…'),
                  error: (_, __) => const SizedBox(),
                  data: (list) => _DropdownField<int>(
                    label: 'Pays de réception',
                    value: _selectedPays,
                    error: _errors['pays_id']?.first,
                    onChanged: (v) => setState(() => _selectedPays = v),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                      ...list.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nom))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                EbiTextField(
                  label: 'Ville', controller: _villeCtrl,
                  hint: 'Lomé, Cotonou, Abidjan…',
                  error: _errors['ville']?.first,
                ),

                const SizedBox(height: 20),
                const _SectionTitle('Votre partenaire cargo (optionnel)'),
                const SizedBox(height: 8),
                const Text(
                  'Le cargo auprès duquel vous expédiez vos colis. Vous pourrez le choisir plus tard.',
                  style: TextStyle(fontSize: 12, color: EbiColors.ink3, height: 1.4),
                ),
                const SizedBox(height: 12),
                cargosAsync.when(
                  loading: () => const _LoadingTile('Chargement des cargos…'),
                  error: (_, __) => const SizedBox(),
                  data: (list) => _DropdownField<int>(
                    label: 'Cargo partenaire',
                    value: _selectedCargo,
                    error: _errors['cargo_id']?.first,
                    onChanged: (v) => setState(() => _selectedCargo = v),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                      ...list.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.nom}${c.paysNom != null ? ' · ${c.paysNom}' : ''}'),
                      )),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CGU
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                  title: const Text(
                    'J\'accepte les conditions d\'utilisation et la politique de confidentialité.',
                    style: TextStyle(fontSize: 12, color: EbiColors.ink2, height: 1.4),
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
                EbiButton(
                  label: 'Créer mon compte',
                  loading: _loading, block: true,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('J\'ai déjà un compte'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: EbiColors.ink3, letterSpacing: 0.6,
    ),
  );
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 44, padding: const EdgeInsets.symmetric(horizontal: 14),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      border: Border.all(color: EbiColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 12, color: EbiColors.ink3)),
    ]),
  );
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.error,
  });
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: EbiColors.ink2,
        )),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(errorText: error),
          isExpanded: true,
        ),
      ],
    );
  }
}
