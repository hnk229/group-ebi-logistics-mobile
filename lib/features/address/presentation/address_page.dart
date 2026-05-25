import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/widgets/ebi_button.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/lottie_loader.dart';
import '../data/address_repository.dart';

/// Page principale : adresse Chine copiable pour AliExpress / Taobao / 1688 / WeChat.
/// L'utilisateur choisit le mode (Aérien / Maritime) → on charge l'adresse correspondante.
class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    final modesAsync = ref.watch(shippingModesProvider);

    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: const Text('Adresse Chine'),
        backgroundColor: EbiColors.white,
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        child: modesAsync.when(
          loading: () => const LottieLoader(),
          error: (e, __) => _ErrorState(
            message: 'Impossible de charger vos adresses.',
            onRetry: () => ref.invalidate(shippingModesProvider),
          ),
          data: (modes) {
            // Aucun mode loué par le cargo → message clair (pas de loader infini).
            if (modes.isEmpty) {
              return const _EmptyModes();
            }
            // Sélectionne par défaut le premier mode disponible.
            final current = (_type != null && modes.contains(_type)) ? _type! : modes.first;
            return _buildForMode(modes, current);
          },
        ),
      ),
    );
  }

  Widget _buildForMode(List<String> modes, String current) {
    final addr = ref.watch(addressProvider(current));
    return Column(children: [
      // Tabs : affichés uniquement si plusieurs modes disponibles.
      if (modes.length > 1)
        Container(
          color: EbiColors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: EbiColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              if (modes.contains('aerial'))
                Expanded(child: _TabBtn(
                  label: 'Aérien', icon: Icons.flight,
                  active: current == 'aerial',
                  onTap: () => setState(() => _type = 'aerial'),
                )),
              if (modes.contains('maritime'))
                Expanded(child: _TabBtn(
                  label: 'Maritime', icon: Icons.directions_boat,
                  active: current == 'maritime',
                  onTap: () => setState(() => _type = 'maritime'),
                )),
            ]),
          ),
        ),

      const SizedBox(height: 8),

      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EbiColors.bluePale,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: EbiColors.blue, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Copiez cette adresse et envoyez-la à votre fournisseur.',
            style: TextStyle(fontSize: 12, color: EbiColors.ink2, height: 1.4),
          )),
        ]),
      ),

      Expanded(
        child: addr.when(
          loading: () => const LottieLoader(),
          error: (e, __) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(addressProvider(current)),
          ),
          data: (a) => _AddressContent(address: a, type: current),
        ),
      ),
    ]);
  }
}

class _EmptyModes extends StatelessWidget {
  const _EmptyModes();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.warehouse_outlined, size: 64, color: EbiColors.ink3),
        SizedBox(height: 12),
        Text('Aucune adresse disponible',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        SizedBox(height: 6),
        Text(
          'Votre cargo n\'a pas encore d\'entrepôt actif en Chine. '
          'Revenez plus tard ou contactez-le.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: EbiColors.ink3, height: 1.4),
        ),
      ]),
    ),
  );
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.icon, required this.active, required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? EbiColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active ? [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 6, offset: const Offset(0, 2),
        )] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: active ? EbiColors.blue : EbiColors.ink3),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? EbiColors.blue : EbiColors.ink3,
          )),
        ],
      ),
    ),
  );
}

class _AddressContent extends StatelessWidget {
  const _AddressContent({required this.address, required this.type});
  final ShippingAddress address;
  final String type;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Bloc adresse à copier
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: type == 'aerial' ? EbiColors.bluePale : EbiColors.successPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    type == 'aerial' ? Icons.flight : Icons.directions_boat,
                    color: type == 'aerial' ? EbiColors.blue : EbiColors.success, size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ENTREPÔT', style: TextStyle(
                    fontSize: 9, color: EbiColors.ink3, letterSpacing: 0.6, fontWeight: FontWeight.w600,
                  )),
                  Text(
                    type == 'aerial' ? 'Mode Aérien' : 'Mode Maritime',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ])),
              ]),
              const SizedBox(height: 12), const Divider(), const SizedBox(height: 12),

              // Le bloc d'adresse (monospace, sélectionnable)
              SelectableText(
                address.address,
                style: EbiTypography.mono(fontSize: 12, color: EbiColors.ink),
              ),
              const SizedBox(height: 16),

              // Bouton copier
              EbiButton(
                label: 'Copier l\'adresse',
                icon: Icons.copy,
                block: true,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: address.address));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.check_circle, color: EbiColors.success, size: 18),
                        SizedBox(width: 8),
                        Text('Adresse copiée — vous pouvez la coller dans votre app shopping.'),
                      ]),
                      backgroundColor: EbiColors.ink,
                    ),
                  );
                },
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Aide instructions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('COMMENT UTILISER ?',
                style: TextStyle(fontSize: 10, color: EbiColors.ink3, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _Step(num: '1', text: 'Copiez l\'adresse ci-dessus.'),
              _Step(num: '2', text: 'Envoyez-la à votre fournisseur comme adresse de livraison.'),
              _Step(num: '3', text: 'Vous serez notifié dès l\'arrivée de votre colis à l\'entrepôt.'),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.num, required this.text});
  final String num;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 22, height: 22, alignment: Alignment.center,
        decoration: const BoxDecoration(color: EbiColors.blue, shape: BoxShape.circle),
        child: Text(num, style: const TextStyle(
          color: EbiColors.white, fontSize: 11, fontWeight: FontWeight.w700,
        )),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.warning_amber, size: 64, color: EbiColors.warning),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: EbiColors.ink2)),
      const SizedBox(height: 16),
      TextButton(onPressed: onRetry, child: const Text('Réessayer')),
    ]),
  ));
}
