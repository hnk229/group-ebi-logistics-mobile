import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../auth/presentation/auth_controller.dart';

/// Page chat client → partenaire (cargo). Version simple : récupère la
/// conversation active + messages + envoi.
/// Le temps réel via Reverb sera branché plus tard (push notifs en attendant).
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  int? _conversationId;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final api = ref.read(apiClientProvider);
    final user = ref.read(currentUserProvider);
    if (user?.cargoId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // 1. Récupère la conversation existante OU la crée avec le cargo.
      final convResp = await api.post('/api/client/cargos/${user!.cargoId}/conversation');
      final conv = (convResp.data as Map<String, dynamic>)['conversation'] as Map<String, dynamic>;
      _conversationId = conv['id'] as int;

      // 2. Charge les messages
      await _loadMessages();
    } catch (_) {
      // silencieux
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    final api = ref.read(apiClientProvider);
    final resp = await api.get('/api/client/conversations/$_conversationId');
    final msgs = (resp.data as Map<String, dynamic>)['messages'] as List;
    setState(() {
      _messages = msgs.cast<Map<String, dynamic>>();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    setState(() => _sending = true);
    final api = ref.read(apiClientProvider);
    try {
      final resp = await api.post(
        '/api/client/conversations/$_conversationId/messages',
        data: {'type': 'text', 'content': text},
      );
      final msg = (resp.data as Map<String, dynamic>)['message'] as Map<String, dynamic>;
      setState(() {
        _messages.add(msg);
        _msgCtrl.clear();
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Envoi impossible.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myId = user?.id;

    return Scaffold(
      backgroundColor: EbiColors.surface,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user?.cargo?.nom ?? 'Mon cargo',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const Text('En ligne', style: TextStyle(fontSize: 11, color: EbiColors.ink3)),
        ]),
      ),
      body: Column(children: [
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: EbiColors.ink3),
                  SizedBox(height: 12),
                  Text('Aucun message', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Posez votre question à votre cargo, ils vous répondront.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: EbiColors.ink3)),
                ]),
              ))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final isMine = m['sender_id'] == myId;
                  return _Bubble(
                    text: (m['content'] ?? '') as String,
                    isMine: isMine,
                    time: m['created_at'] as String?,
                  );
                },
              ),
        ),
        // Input
        Container(
          decoration: const BoxDecoration(
            color: EbiColors.white,
            border: Border(top: BorderSide(color: EbiColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: SafeArea(child: Row(children: [
            Expanded(child: TextField(
              controller: _msgCtrl,
              minLines: 1, maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Écrivez un message…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 4),
            Material(
              color: EbiColors.blue, shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _send,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                        strokeWidth: 2, valueColor: AlwaysStoppedAnimation(EbiColors.white),
                      ))
                    : const Icon(Icons.send, color: EbiColors.white, size: 18),
                ),
              ),
            ),
          ])),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.isMine, this.time});
  final String text;
  final bool isMine;
  final String? time;

  @override
  Widget build(BuildContext context) => Align(
    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMine ? EbiColors.blue : EbiColors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        border: isMine ? null : Border.all(color: EbiColors.border),
      ),
      child: Text(text, style: TextStyle(
        color: isMine ? EbiColors.white : EbiColors.ink, fontSize: 14, height: 1.4,
      )),
    ),
  );
}
