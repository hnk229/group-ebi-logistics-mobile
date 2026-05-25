import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../data/public_refs_repository.dart';

/// Sélecteur de cargo "pro" affiché dans le formulaire d'inscription / profil.
///
/// Au lieu d'un Dropdown sec, affiche :
///   - une carte cliquable pour chaque cargo (logo, nom, pays, prix kg / m³, délai)
///   - au tap → ouvre une bottom sheet détaillée (description, tarifs complets,
///     contact, statistiques) avec bouton "Choisir ce cargo"
///
/// La carte sélectionnée est visuellement distinguée (bordure bleue + check).
class CargoPicker extends ConsumerStatefulWidget {
  const CargoPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Cargo partenaire',
    this.helper,
    this.error,
  });

  /// id du cargo actuellement sélectionné (ou null).
  final int? value;
  final ValueChanged<PublicCargo?> onChanged;
  final String label;
  final String? helper;
  final String? error;

  @override
  ConsumerState<CargoPicker> createState() => _CargoPickerState();
}

class _CargoPickerState extends ConsumerState<CargoPicker> {
  @override
  Widget build(BuildContext context) {
    final cargosAsync = ref.watch(cargosFutureProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: EbiColors.ink2),
        ),
        const SizedBox(height: 8),

        cargosAsync.when(
          loading: () => const _Skeleton(),
          error: (e, _) => _ErrorBox(
            message: extractErrorMessage(e),
            onRetry: () => ref.invalidate(cargosFutureProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EbiColors.surface,
                  border: Border.all(color: EbiColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Aucun cargo disponible pour le moment.',
                  style: TextStyle(fontSize: 12, color: EbiColors.ink3),
                ),
              );
            }
            return Column(
              children: [
                for (final c in list) ...[
                  _CargoCard(
                    cargo: c,
                    selected: widget.value == c.id,
                    onTap: () => _openDetail(c),
                  ),
                  const SizedBox(height: 8),
                ],
                if (widget.value != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => widget.onChanged(null),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Désélectionner', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: EbiColors.ink3),
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Text(widget.error!, style: const TextStyle(fontSize: 12, color: EbiColors.danger)),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(widget.helper!, style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
        ],
      ],
    );
  }

  Future<void> _openDetail(PublicCargo cargo) async {
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CargoDetailSheet(slug: cargo.slug, alreadySelected: widget.value == cargo.id),
    );
    if (chosen == true) widget.onChanged(cargo);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte cargo (résumé)
// ─────────────────────────────────────────────────────────────────────────────

class _CargoCard extends StatelessWidget {
  const _CargoCard({required this.cargo, required this.selected, required this.onTap});
  final PublicCargo cargo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final aerien = cargo.tarifFor('kg');
    final maritime = cargo.tarifFor('cbm');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? EbiColors.bluePale.withValues(alpha: 0.5) : EbiColors.white,
            border: Border.all(
              color: selected ? EbiColors.blue : EbiColors.border,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EbiColors.surface2,
                      border: Border.all(color: EbiColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cargo.logoUrl != null
                        ? Image.network(cargo.logoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _initialFallback(cargo.initial))
                        : _initialFallback(cargo.initial),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cargo.nom,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            if (selected) const Icon(Icons.check_circle, color: EbiColors.blue, size: 18),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [if (cargo.paysNom != null) cargo.paysNom!, if (cargo.ville != null) cargo.ville!].join(' · '),
                          style: const TextStyle(fontSize: 11, color: EbiColors.ink3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _TarifChip(label: 'Aérien', tarif: aerien, unit: 'kg')),
                  const SizedBox(width: 6),
                  Expanded(child: _TarifChip(label: 'Maritime', tarif: maritime, unit: 'm³')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialFallback(String initial) => Center(
        child: Text(initial,
            style: const TextStyle(fontWeight: FontWeight.w700, color: EbiColors.ink3)),
      );
}

class _TarifChip extends StatelessWidget {
  const _TarifChip({required this.label, required this.tarif, required this.unit});
  final String label;
  final PublicCargoTarif? tarif;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: EbiColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
          Expanded(
            child: tarif != null && tarif!.prix != null
                ? Text(
                    '${tarif!.prix!.round().toString()} XOF/$unit'
                    '${tarif!.transitDays != null ? ' · ${tarif!.transitDays}j' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EbiColors.ink),
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text('—', style: TextStyle(fontSize: 11, color: EbiColors.ink3)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet de détail
// ─────────────────────────────────────────────────────────────────────────────

class CargoDetailSheet extends ConsumerStatefulWidget {
  const CargoDetailSheet({super.key, required this.slug, this.alreadySelected = false});
  final String slug;
  final bool alreadySelected;

  @override
  ConsumerState<CargoDetailSheet> createState() => _CargoDetailSheetState();
}

class _CargoDetailSheetState extends ConsumerState<CargoDetailSheet> {
  PublicCargoDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _detail = await ref.read(publicRefsRepositoryProvider).cargoDetail(widget.slug);
    } catch (e) {
      _error = extractErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: EbiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: EbiColors.border, borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: EbiColors.danger, size: 36),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: EbiColors.ink2)),
                    const SizedBox(height: 12),
                    EbiButton(label: 'Réessayer', onPressed: _load,
                        variant: EbiButtonVariant.secondary, size: EbiButtonSize.sm),
                  ],
                ),
              )
            else if (_detail != null)
              Flexible(child: _buildContent(_detail!)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PublicCargoDetail c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header : logo + nom + pays + close
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EbiColors.surface2,
                  border: Border.all(color: EbiColors.border, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: c.logoUrl != null
                    ? Image.network(c.logoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(child: Text(c.initial,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))))
                    : Center(child: Text(c.initial,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EbiColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      [if (c.paysNom != null) c.paysNom!, if (c.ville != null) c.ville!].join(' · '),
                      style: const TextStyle(fontSize: 12, color: EbiColors.ink3),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close, color: EbiColors.ink3),
              ),
            ],
          ),

          // Stats
          if (c.totalColis > 0 || c.totalClients > 0 || c.rating > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (c.totalColis > 0) _stat('${c.totalColis}', 'colis livrés'),
                if (c.totalClients > 0) _stat('${c.totalClients}', 'clients'),
                if (c.rating > 0) _stat(c.rating.toStringAsFixed(1), 'note / 5'),
              ],
            ),
          ],

          // Description
          if (c.description != null && c.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('À propos'),
            const SizedBox(height: 6),
            Text(c.description!,
                style: const TextStyle(fontSize: 13, color: EbiColors.ink2, height: 1.5)),
          ],

          // Tarifs
          const SizedBox(height: 18),
          const _SectionTitle('Tarifs et délais'),
          const SizedBox(height: 8),
          if (c.tarifs.isEmpty)
            const Text('Ce cargo n\'a pas encore publié ses tarifs.',
                style: TextStyle(fontSize: 12, color: EbiColors.ink3))
          else
            Column(
              children: [
                for (final t in c.tarifs) _TarifRow(tarif: t),
              ],
            ),

          // Contact
          if (c.telephone != null || c.whatsapp != null || c.emailPublic != null || c.adresse != null) ...[
            const SizedBox(height: 18),
            const _SectionTitle('Contact'),
            const SizedBox(height: 8),
            if (c.adresse != null) _contactLine(Icons.place_outlined, c.adresse!),
            if (c.telephone != null) _contactLine(Icons.phone_outlined, c.telephone!),
            if (c.whatsapp != null) _contactLine(Icons.chat_outlined, c.whatsapp!),
            if (c.emailPublic != null) _contactLine(Icons.mail_outline, c.emailPublic!),
          ],

          // CTA
          const SizedBox(height: 24),
          if (widget.alreadySelected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EbiColors.bluePale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: EbiColors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Ce cargo est actuellement votre choix.',
                      style: TextStyle(fontSize: 13, color: EbiColors.ink2))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            EbiButton(
              label: 'Fermer',
              variant: EbiButtonVariant.secondary,
              block: true,
              onPressed: () => Navigator.pop(context, false),
            ),
          ] else ...[
            EbiButton(
              label: 'Choisir ce cargo',
              icon: Icons.check,
              block: true,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: EbiColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EbiColors.blue)),
              Text(label, style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
            ],
          ),
        ),
      );

  Widget _contactLine(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: EbiColors.ink3),
            const SizedBox(width: 8),
            Expanded(child: Text(value,
                style: const TextStyle(fontSize: 13, color: EbiColors.ink2))),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 11, letterSpacing: 0.5,
          fontWeight: FontWeight.w700, color: EbiColors.ink3));
}

class _TarifRow extends StatelessWidget {
  const _TarifRow({required this.tarif});
  final PublicCargoTarif tarif;
  @override
  Widget build(BuildContext context) {
    final unit = tarif.mode == 'kg' ? 'kg' : 'm³';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: EbiColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tarif.mode == 'kg' ? Icons.flight_takeoff : Icons.directions_boat,
                size: 18, color: EbiColors.blue,
              ),
              const SizedBox(width: 8),
              Text(tarif.label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              if (tarif.transitDays != null)
                Text('${tarif.transitDays} jours',
                    style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tarif.prix != null
                ? '${tarif.prix!.round()} XOF / $unit'
                : 'Tarif non communiqué',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: tarif.prix != null ? EbiColors.blueDark : EbiColors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(2, (_) => Container(
              height: 100, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: EbiColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EbiColors.dangerPale,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(message,
                style: const TextStyle(fontSize: 12, color: EbiColors.danger))),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
}
