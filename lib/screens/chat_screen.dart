import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  late Box<MessageModel> _box;
  bool _isRecording = false;
  String? _replyToUserId;
  String? _replyToNick;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<MessageModel>('messages');
    StorageService.cleanExpiredMessages();
    widget.nearby.onMessageReceived = _onMsg;
  }

  void _onMsg(MessageModel m) {
    if (m.roomId != widget.room.id) return;
    final myId = StorageService.getDeviceId();
    if (m.isPrivate && m.recipientId != myId && m.senderId != myId) return;
    if (_box.values.any((x) => x.id == m.id)) return;
    _box.add(m); _bottom();
  }

  List<MessageModel> get _msgs {
    final myId = StorageService.getDeviceId();
    return _box.values.where((m) {
      if (m.roomId != widget.room.id || m.isExpired) return false;
      if (m.isPrivate) return m.senderId == myId || m.recipientId == myId;
      return true;
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Duration get _ttl => Duration(hours: widget.room.messageTtlHours);

  Future<void> _send() async {
    final t = _txt.text.trim();
    if (t.isEmpty) return;
    _txt.clear();
    final m = MessageModel(
      id: const Uuid().v4(), roomId: widget.room.id,
      senderId: StorageService.getDeviceId(),
      senderNick: StorageService.getNickname() ?? 'User',
      text: t, createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_ttl),
      messageType: 'text', recipientId: _replyToUserId,
    );
    _box.add(m); widget.nearby.sendMessage(m);
    setState(() { _replyToUserId = null; _replyToNick = null; });
    _bottom();
  }

  Future<void> _img() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 60);
    if (xf == null) return;
    final m = MessageModel(
      id: const Uuid().v4(), roomId: widget.room.id,
      senderId: StorageService.getDeviceId(),
      senderNick: StorageService.getNickname() ?? 'User',
      text: '[Imagem]', createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_ttl),
      messageType: 'image', imagePath: xf.path,
    );
    _box.add(m); widget.nearby.sendMessage(m); _bottom();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, const Uuid().v4() + '.aac');
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 22050),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;
    final m = MessageModel(
      id: const Uuid().v4(), roomId: widget.room.id,
      senderId: StorageService.getDeviceId(),
      senderNick: StorageService.getNickname() ?? 'User',
      text: '[Audio]', createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_ttl),
      messageType: 'audio', audioPath: path, recipientId: _replyToUserId,
    );
    _box.add(m); widget.nearby.sendMessage(m);
    setState(() { _replyToUserId = null; _replyToNick = null; }); _bottom();
  }

  Future<void> _playAudio(String path) async {
    try { await _player.setFilePath(path); await _player.play(); } catch (_) {}
  }

  void _selectRecipient(BuildContext ctx) {
    final myId = StorageService.getDeviceId();
    final seen = <String>{};
    final senders = _msgs.where((m) => m.senderId != myId && seen.add(m.senderId))
      .map((m) => MapEntry(m.senderId, m.senderNick)).toList();
    if (senders.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nenhum outro usuario na sala.')));
      return;
    }
    showModalBottomSheet(context: ctx, builder: (_) => ListView(shrinkWrap: true, children: [
      const ListTile(title: Text('Enviar para:', style: TextStyle(fontWeight: FontWeight.bold))),
      ListTile(leading: const Icon(Icons.public), title: const Text('Todos (publica)'),
        onTap: () { setState(() { _replyToUserId = null; _replyToNick = null; }); Navigator.pop(ctx); }),
      ...senders.map((e) => ListTile(
        leading: const Icon(Icons.person), title: Text(e.value),
        onTap: () { setState(() { _replyToUserId = e.key; _replyToNick = e.value; }); Navigator.pop(ctx); },
      )).toList(),
    ]));
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  });

  @override void dispose() {
    _txt.dispose(); _scroll.dispose(); _recorder.dispose(); _player.dispose();
    widget.nearby.onMessageReceived = null; super.dispose();
  }

  Widget _micOrSend() {
    if (_txt.text.trim().isEmpty) {
      return GestureDetector(
        onLongPressStart: (_) => _startRecording(),
        onLongPressEnd: (_) => _stopRecording(),
        child: CircleAvatar(
          backgroundColor: _isRecording ? Colors.red : AppTheme.primary,
          child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.black, size: 20),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: AppTheme.primary,
      child: IconButton(icon: const Icon(Icons.send, color: Colors.black, size: 18), onPressed: _send),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
          widget.room.messageTtlHours < 8760
            ? 'Msgs expiram em ' + widget.room.messageTtlHours.toString() + 'h'
            : 'Mensagens permanentes',
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ])),
      body: Column(children: [
        StreamBuilder<String>(stream: widget.nearby.statusStream, initialData: 'Iniciando...',
          builder: (_, s) => Container(
            color: AppTheme.primary.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Row(children: [
              const Icon(Icons.wifi, size: 14, color: Colors.white), const SizedBox(width: 6),
              Expanded(child: Text(s.data!, style: const TextStyle(fontSize: 11, color: Colors.white))),
            ]))),
        if (_replyToNick != null)
          Container(
            color: AppTheme.primary.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              const Icon(Icons.lock_outline, size: 14, color: AppTheme.primary), const SizedBox(width: 6),
              Expanded(child: Text('Privado para: ' + _replyToNick!,
                style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600))),
              IconButton(icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() { _replyToUserId = null; _replyToNick = null; })),
            ]),
          ),
        Expanded(child: ValueListenableBuilder(
          valueListenable: _box.listenable(),
          builder: (_, __, ___) {
            final msgs = _msgs;
            if (msgs.isEmpty) return const Center(child: Text('Sem mensagens. Seja o primeiro!',
              style: TextStyle(color: AppTheme.textSecondary)));
            return ListView.builder(controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                final isMe = m.senderId == StorageService.getDeviceId();
                if (m.isAudio) return _buildAudioBubble(m, isMe);
                return MessageBubble(message: m, isMe: isMe);
              });
          })),
        Container(color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 16),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.image_outlined), onPressed: _img, color: AppTheme.textSecondary),
            IconButton(
              icon: Icon(_replyToNick != null ? Icons.lock : Icons.person_outline),
              onPressed: () => _selectRecipient(context),
              color: _replyToNick != null ? AppTheme.primary : AppTheme.textSecondary,
              tooltip: 'Mensagem privada',
            ),
            Expanded(child: TextField(controller: _txt, maxLines: null,
              textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Mensagem...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)))),
            const SizedBox(width: 4),
            _micOrSend(),
          ])),
      ]),
    );
  }

  Widget _buildAudioBubble(MessageModel m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary.withOpacity(0.85) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (m.isPrivate) const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.lock_outline, size: 12, color: Colors.grey)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(m.isPrivate ? m.senderNick + ' (privado)' : m.senderNick,
              style: TextStyle(fontSize: 10, color: isMe ? Colors.black54 : AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.graphic_eq, size: 18),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () { if (m.audioPath != null) _playAudio(m.audioPath!); },
                child: const Icon(Icons.play_circle, size: 32, color: AppTheme.primary)),
              const SizedBox(width: 4),
              const Text('Toque para ouvir', style: TextStyle(fontSize: 10)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
