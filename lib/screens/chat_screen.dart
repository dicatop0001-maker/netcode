import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';
import '../models/room_model.dart';
import '../services/storage_service.dart';
import '../services/nearby_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final RoomModel room;
  final NearbyService nearby;
  const ChatScreen({super.key, required this.room, required this.nearby});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _txt = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  late Box<MessageModel> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<MessageModel>('messages');
    StorageService.cleanExpiredMessages();
    widget.nearby.onMessageReceived = _onMsg;
  }

  void _onMsg(MessageModel m) {
    if (m.roomId != widget.room.id) return;
    if (_box.values.any((x) => x.id == m.id)) return;
    _box.add(m);
    _bottom();
  }

  List<MessageModel> get _msgs => _box.values
      .where((m) => m.roomId == widget.room.id && !m.isExpired)
      .toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> _send() async {
    final t = _txt.text.trim();
    if (t.isEmpty) return;
    _txt.clear();
    final m = MessageModel(id: const Uuid().v4(), roomId: widget.room.id,
      senderId: StorageService.getDeviceId(),
      senderNick: StorageService.getNickname() ?? 'User',
      text: t, createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)));
    _box.add(m);
    widget.nearby.sendMessage(m);
    _bottom();
  }

  Future<void> _img() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery,
        maxWidth: 800, maxHeight: 800, imageQuality: 60);
    if (xf == null) return;
    final m = MessageModel(id: const Uuid().v4(), roomId: widget.room.id,
      senderId: StorageService.getDeviceId(),
      senderNick: StorageService.getNickname() ?? 'User',
      text: '[Imagem]', createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      imagePath: xf.path);
    _box.add(m);
    widget.nearby.sendMessage(m);
    _bottom();
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  });

  @override void dispose() {
    _txt.dispose(); _scroll.dispose();
    widget.nearby.onMessageReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.room.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          StreamBuilder<int>(stream: widget.nearby.peerCountStream, initialData: 0,
            builder: (_, s) => Text('${s.data} dispositivo(s)',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        ])),
      body: Column(children: [
        StreamBuilder<String>(stream: widget.nearby.statusStream, initialData: 'Iniciando...',
          builder: (_, s) => Container(
            color: s.data!.contains('conectado') || s.data!.contains('ativo')
                ? AppTheme.primary.withOpacity(0.8) : AppTheme.surfaceLight,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Row(children: [
              Icon(s.data!.contains('conectado') ? Icons.wifi : Icons.wifi_find,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(child: Text(s.data!,
                  style: const TextStyle(fontSize: 11, color: Colors.white))),
            ]))),
        Expanded(child: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (_, __, ___) {
            final msgs = _msgs;
            if (msgs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 12),
              const Text('Sem mensagens. Seja o primeiro!',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ]));
            return ListView.builder(controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) => MessageBubble(
                  message: msgs[i],
                  isMe: msgs[i].senderId == StorageService.getDeviceId()));
          })),
        Container(color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.image_outlined), onPressed: _img,
                color: AppTheme.textSecondary),
            Expanded(child: TextField(controller: _txt, maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'Mensagem...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
            const SizedBox(width: 8),
            CircleAvatar(backgroundColor: AppTheme.primary,
              child: IconButton(icon: const Icon(Icons.send, color: Colors.black, size: 18),
                  onPressed: _send)),
          ])),
      ]),
    );
  }
}
