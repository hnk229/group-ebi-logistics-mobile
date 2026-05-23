import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/utils/date_format.dart';
import '../data/colis_models.dart';
import '../data/colis_repository.dart';

class ColisDetailPage extends ConsumerWidget {
  const ColisDetailPage({super.key, required this.colisId});
  final int colisId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(colisDetailProvider(colisId));

    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Détail du colis'),
        backgroundColor: EbiColors.white,
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur de chargement.')),
        data: (c) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(colisDetailProvider(colisId));
            await ref.read(colisDetailProvider(colisId).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(colis: c),
              const SizedBox(height: 16),
              _TimelineCard(colis: c),
              const SizedBox(height: 16),
              if (c.articles.isNotEmpty) _ArticlesCard(articles: c.articles),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.colis});
  final Colis colis;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: colis.transport == 'Avion' ? EbiColors.bluePale : EbiColors.successPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                colis.transport == 'Avion' ? Icons.flight : Icons.directions_boat,
                color: colis.transport == 'Avion' ? EbiColors.blue : EbiColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Code interne', style: const TextStyle(fontSize: 10, color: EbiColors.ink3)),
              Text(colis.codesfGlobal, style: EbiTypography.mono(fontSize: 14, fontWeight: FontWeight.w600)),
            ])),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: colis.codesfGlobal));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copié')),
                );
              },
            ),
          ]),

          if (colis.trackingNumber != null) ...[
            const SizedBox(height: 12), const Divider(),
            const SizedBox(height: 8),
            _InfoRow(label: 'N° de suivi (transporteur)', value: colis.trackingNumber!, mono: true, copy: true),
          ],

          const SizedBox(height: 12), const Divider(), const SizedBox(height: 8),
          _InfoRow(label: 'Statut', valueWidget: _Badge(colis.statut)),
          _InfoRow(label: 'Transport', value: colis.transport),
          _InfoRow(label: 'Poids', value: '${colis.poidsTotal.toStringAsFixed(2)} kg'),
          _InfoRow(label: 'Volume', value: '${colis.cbmTotal.toStringAsFixed(4)} m³'),
          _InfoRow(label: 'Prix transport', value: '${colis.prixTotal.toStringAsFixed(0)} XOF'),
          _InfoRow(label: 'Destination', value: '${colis.ville}${colis.paysNom != null ? ', ${colis.paysNom}' : ''}'),
          if (colis.telephoneDestinataire != null)
            _InfoRow(label: 'Téléphone', value: colis.telephoneDestinataire!),
        ]),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.colis});
  final Colis colis;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep('Enregistré', colis.createdAt, true),
      _TimelineStep('Payé', colis.colisPayeAt, colis.colisPayeAt != null),
      _TimelineStep('En transit', colis.colisTransitAt, colis.colisTransitAt != null),
      _TimelineStep('Arrivé', colis.colisArriveAt, colis.colisArriveAt != null),
      _TimelineStep('Livré', colis.colisLivreAt, colis.colisLivreAt != null),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EbiColors.ink)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _StepRow(step: steps[i], isLast: i == steps.length - 1),
        ]),
      ),
    );
  }
}

class _TimelineStep {
  _TimelineStep(this.label, this.date, this.done);
  final String label;
  final String? date;
  final bool done;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});
  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.done ? EbiColors.blue : EbiColors.border;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: step.done ? EbiColors.blue : EbiColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: step.done
                ? const Icon(Icons.check, size: 14, color: EbiColors.white)
                : null,
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: color, margin: const EdgeInsets.symmetric(vertical: 2))),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.label, style: TextStyle(
              fontWeight: step.done ? FontWeight.w600 : FontWeight.w400,
              color: step.done ? EbiColors.ink : EbiColors.ink3,
            )),
            if (step.date != null)
              Text(formatDateTimeFr(step.date),
                style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
          ]),
        )),
      ]),
    );
  }
}

class _ArticlesCard extends StatelessWidget {
  const _ArticlesCard({required this.articles});
  final List<ColisArticle> articles;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Articles (${articles.length})',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...articles.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              if (a.photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: a.photoPath!,
                    width: 56, height: 56, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56, height: 56, color: EbiColors.surface2,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56, height: 56, color: EbiColors.surface2,
                      child: const Icon(Icons.image, color: EbiColors.ink3),
                    ),
                  ),
                )
              else
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: EbiColors.surface2, borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: EbiColors.ink3),
                ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Quantité : ${a.qte}${a.poids > 0 ? ' · ${a.poids.toStringAsFixed(2)} kg' : ''}',
                  style: const TextStyle(fontSize: 11, color: EbiColors.ink3)),
              ])),
            ]),
          )),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget, this.mono = false, this.copy = false});
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool mono;
  final bool copy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 140,
        child: Text(label, style: const TextStyle(fontSize: 12, color: EbiColors.ink3))),
      const SizedBox(width: 8),
      Expanded(child: valueWidget ?? Text(
        value ?? '—',
        style: mono
            ? EbiTypography.mono(fontSize: 12, color: EbiColors.ink)
            : const TextStyle(fontSize: 13, color: EbiColors.ink, fontWeight: FontWeight.w500),
      )),
      if (copy && value != null)
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copié'), duration: Duration(seconds: 1)),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.copy, size: 16, color: EbiColors.ink3),
          ),
        ),
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.status);
  final String status;

  Color get _color {
    if (status == 'Livré' || status == 'Arrivé') return EbiColors.success;
    if (status == 'En transit' || status == 'Payé') return EbiColors.blue;
    if (status == 'En attente') return EbiColors.warning;
    return EbiColors.ink3;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color)),
  );
}
