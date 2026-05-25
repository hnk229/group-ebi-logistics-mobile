import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/ebi_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/article_draft.dart';
import '../data/colis_repository.dart';

/// Page de déclaration d'un colis par le client.
///
/// Le client renseigne :
///   - le type de transport (Aérien / Maritime)
///   - la ville de livraison et le téléphone destinataire (pré-remplis depuis son profil)
///   - le numéro de suivi expéditeur (optionnel)
///   - 1 à 30 articles : nom, quantité, code suivi, transporteur, URL d'achat,
///     prix d'achat + devise, notes, photo (optionnelle)
///
/// Pas de poids ni de dimensions : c'est le partenaire qui les ajoute à
/// réception physique, puis calcule le prix de transport.
class AddColisPage extends ConsumerStatefulWidget {
  const AddColisPage({super.key});

  @override
  ConsumerState<AddColisPage> createState() => _AddColisPageState();
}

class _AddColisPageState extends ConsumerState<AddColisPage> {
  final _formKey = GlobalKey<FormState>();
  final _villeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  String _transportLabel = 'Avion'; // Avion | Bateau
  int? _transportTypeId;
  int? _entrepotId;
  bool _loading = true;
  bool _submitting = false;
  String? _bootstrapError;

  final List<ArticleDraft> _articles = [ArticleDraft()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _villeCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(colisRepositoryProvider);
    final user = ref.read(currentUserProvider);
    try {
      final types = await repo.transportTypes();
      // Sélectionne le type Avion par défaut s'il existe.
      final avion = types.firstWhere(
        (t) => t.code == 'aerial' || t.label.toLowerCase().contains('avion'),
        orElse: () => types.isNotEmpty ? types.first : TransportTypeRef(id: 0, code: '', label: '', mode: 'kg'),
      );
      _transportTypeId = avion.id;
      _transportLabel = avion.label.isNotEmpty ? avion.label : 'Avion';

      final entId = await repo.entrepotIdForMode(avion.mode);
      _entrepotId = entId;

      // Pré-remplissage depuis le profil utilisateur si dispo.
      if (user != null) {
        _telCtrl.text = user.phone ?? '';
        _villeCtrl.text = user.ville ?? '';
      }
    } catch (e) {
      _bootstrapError = extractErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setTransport(String label, String mode) async {
    setState(() {
      _transportLabel = label;
      _loading = true;
    });
    final repo = ref.read(colisRepositoryProvider);
    try {
      final types = await repo.transportTypes();
      final t = types.firstWhere(
        (t) => t.mode == mode,
        orElse: () => TransportTypeRef(id: 0, code: '', label: label, mode: mode),
      );
      _transportTypeId = t.id > 0 ? t.id : null;
      _entrepotId = await repo.entrepotIdForMode(mode);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addArticle() {
    setState(() => _articles.add(ArticleDraft()));
  }

  void _removeArticle(int idx) {
    if (_articles.length <= 1) return;
    setState(() => _articles.removeAt(idx));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_articles.every((a) => a.isEmpty)) {
      _snack('Ajoutez au moins un article avec un nom.');
      return;
    }
    if (_entrepotId == null) {
      _snack('Aucun entrepôt disponible pour ce mode de transport. Contactez votre cargo.');
      return;
    }

    setState(() => _submitting = true);
    final repo = ref.read(colisRepositoryProvider);
    try {
      // Upload des photos en premier (séquentiel pour limiter la conso réseau).
      for (final a in _articles.where((a) => !a.isEmpty && a.photo != null)) {
        a.photoPath = await repo.uploadArticlePhoto(a.photo!);
      }

      final colis = await repo.create(
        entrepotId: _entrepotId!,
        transportTypeId: _transportTypeId,
        transport: _transportLabel,
        ville: _villeCtrl.text,
        telephoneDestinataire: _telCtrl.text,
        articles: _articles.where((a) => !a.isEmpty).toList(),
      );

      if (!mounted) return;
      _snack('Colis déclaré (${colis.codesfGlobal}). Vous serez notifié.', color: EbiColors.success);
      // Refresh de la liste + retour
      ref.invalidate(colisListProvider);
      ref.invalidate(colisStatsProvider);
      context.pop();
    } catch (e) {
      _snack(extractErrorMessage(e), color: EbiColors.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Déclarer un colis'),
        backgroundColor: EbiColors.white,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bootstrapError != null
              ? _ErrorState(message: _bootstrapError!, onRetry: _bootstrap)
              : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Mode de transport',
            child: Row(
              children: [
                Expanded(
                  child: _TransportChoice(
                    icon: Icons.flight_takeoff,
                    label: 'Aérien',
                    sub: 'Plus rapide',
                    selected: _transportLabel == 'Avion',
                    onTap: () => _setTransport('Avion', 'kg'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TransportChoice(
                    icon: Icons.directions_boat,
                    label: 'Maritime',
                    sub: 'Plus économique',
                    selected: _transportLabel == 'Bateau',
                    onTap: () => _setTransport('Bateau', 'cbm'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Livraison',
            child: Column(
              children: [
                EbiTextField(
                  label: 'Ville de livraison',
                  controller: _villeCtrl,
                  required: true,
                  hint: 'Ex : Lomé',
                ),
                const SizedBox(height: 12),
                EbiTextField(
                  label: 'Téléphone du destinataire',
                  controller: _telCtrl,
                  required: true,
                  keyboardType: TextInputType.phone,
                  hint: '+228 90 00 00 00',
                ),
                // Le numéro de suivi se renseigne par article (voir « Code de suivi »
                // dans chaque article), pas au niveau global du colis.
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Articles (${_articles.length})',
            trailing: TextButton.icon(
              onPressed: _addArticle,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(foregroundColor: EbiColors.blue),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _articles.length; i++) ...[
                  _ArticleCard(
                    index: i + 1,
                    article: _articles[i],
                    canDelete: _articles.length > 1,
                    onDelete: () => _removeArticle(i),
                    onChanged: () => setState(() {}),
                  ),
                  if (i < _articles.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EbiColors.bluePale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: EbiColors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Le poids, les dimensions et le prix de transport seront ajoutés par votre cargo dès la réception du colis.",
                    style: TextStyle(fontSize: 12, color: EbiColors.ink2, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // espace pour le bottom bar
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_loading || _bootstrapError != null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: EbiColors.white,
        border: Border(top: BorderSide(color: EbiColors.border)),
      ),
      child: EbiButton(
        label: _submitting ? 'Envoi en cours…' : 'Envoyer la déclaration',
        onPressed: _submitting ? null : _submit,
        loading: _submitting,
        block: true,
        icon: Icons.send_outlined,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sections & widgets locaux
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EbiColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EbiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: EbiColors.ink,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TransportChoice extends StatelessWidget {
  const _TransportChoice({
    required this.icon,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? EbiColors.bluePale : EbiColors.surface,
          border: Border.all(
            color: selected ? EbiColors.blue : EbiColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? EbiColors.blue : EbiColors.ink3),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: selected ? EbiColors.blue : EbiColors.ink,
              ),
            ),
            Text(sub, style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatefulWidget {
  const _ArticleCard({
    required this.index,
    required this.article,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });
  final int index;
  final ArticleDraft article;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qteCtrl;
  late final TextEditingController _codesfCtrl;
  late final TextEditingController _transporteurCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _prixCtrl;
  late final TextEditingController _notesCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.article.name)..addListener(() {
      widget.article.name = _nameCtrl.text;
      widget.onChanged();
    });
    _qteCtrl = TextEditingController(text: widget.article.qte.toString())..addListener(() {
      widget.article.qte = int.tryParse(_qteCtrl.text) ?? 1;
    });
    _codesfCtrl = TextEditingController(text: widget.article.codesf)..addListener(() => widget.article.codesf = _codesfCtrl.text);
    _transporteurCtrl = TextEditingController(text: widget.article.transporteur)..addListener(() => widget.article.transporteur = _transporteurCtrl.text);
    _urlCtrl = TextEditingController(text: widget.article.urlAchat)..addListener(() => widget.article.urlAchat = _urlCtrl.text);
    _prixCtrl = TextEditingController(text: widget.article.prixAchat)..addListener(() => widget.article.prixAchat = _prixCtrl.text);
    _notesCtrl = TextEditingController(text: widget.article.notes)..addListener(() => widget.article.notes = _notesCtrl.text);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qteCtrl.dispose();
    _codesfCtrl.dispose();
    _transporteurCtrl.dispose();
    _urlCtrl.dispose();
    _prixCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (src == null) return;
    final file = await picker.pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    if (file != null) {
      setState(() => widget.article.photo = File(file.path));
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EbiColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EbiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: EbiColors.blue, shape: BoxShape.circle),
                child: Text(
                  widget.index.toString(),
                  style: const TextStyle(color: EbiColors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Article', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              if (widget.canDelete)
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20, color: EbiColors.danger),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          EbiTextField(
            label: 'Nom de l\'article',
            controller: _nameCtrl,
            required: true,
            hint: 'Ex : iPhone 15 Pro',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: EbiTextField(
                  label: 'Quantité',
                  controller: _qteCtrl,
                  required: true,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _PriceField(
                  controller: _prixCtrl,
                  devise: widget.article.devise,
                  onDeviseChanged: (d) {
                    setState(() => widget.article.devise = d);
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PhotoPicker(file: widget.article.photo, onPick: _pickPhoto, onRemove: () {
            setState(() => widget.article.photo = null);
            widget.onChanged();
          }),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: EbiColors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _expanded ? 'Moins de détails' : 'Plus de détails (code de suivi, URL, notes)',
                    style: const TextStyle(color: EbiColors.blue, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 4),
            EbiTextField(
              label: 'Code de suivi expéditeur',
              controller: _codesfCtrl,
              hint: 'Ex : SF1234567890',
              helper: 'Le numéro fourni par votre vendeur.',
            ),
            const SizedBox(height: 10),
            EbiTextField(
              label: 'Transporteur',
              controller: _transporteurCtrl,
              hint: 'DHL, SF Express, EMS…',
            ),
            const SizedBox(height: 10),
            EbiTextField(
              label: 'Lien d\'achat',
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              hint: 'https://…',
            ),
            const SizedBox(height: 10),
            EbiTextField(
              label: 'Notes',
              controller: _notesCtrl,
              hint: 'Fragile, couleur préférée, etc.',
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.devise, required this.onDeviseChanged});
  final TextEditingController controller;
  final String devise;
  final ValueChanged<String> onDeviseChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prix d\'achat',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: EbiColors.ink2),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: EbiColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EbiColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: EbiColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<String>(
                  value: devise,
                  onChanged: (v) { if (v != null) onDeviseChanged(v); },
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: const ['CFA', 'RMB', 'USD', 'EUR']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.file, required this.onPick, required this.onRemove});
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: EbiColors.white,
            border: Border.all(color: EbiColors.border, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 18, color: EbiColors.blue),
              SizedBox(width: 8),
              Text('Ajouter une photo (optionnel)', style: TextStyle(color: EbiColors.blue, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file!, width: 60, height: 60, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            file!.path.split('/').last,
            style: const TextStyle(fontSize: 12, color: EbiColors.ink3),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close, size: 18, color: EbiColors.ink3),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: EbiColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: EbiColors.ink2)),
            const SizedBox(height: 16),
            EbiButton(label: 'Réessayer', onPressed: onRetry, variant: EbiButtonVariant.secondary, size: EbiButtonSize.sm),
          ],
        ),
      ),
    );
  }
}
