import 'dart:async';
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

    // Gravacao de audio
    bool _isRecording = false;
    int _recSeconds = 0;
    Timer? _recTimer;
    static const int _maxRecSeconds = 10;

    // Mensagem privada
    String? _privateToId;
    String? _privateToNick;

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
          _box.add(m);
          _bottom();
    }

    List<MessageModel> get _msgs {
          final myId = StorageService.getDeviceId();
          return _box.values.where((m) {
                  if (m.roomId != widget.room.id || m.isExpired) return false;
                  if (m.isPrivate) return m.senderId == myId || m.recipientId == myId;
                  return true;
          }).toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    Duration get _ttl => Duration(hours: widget.room.messageTtlHours);

    // ── Enviar texto ────────────────────────────────────────────────────────────
    Future<void> _send() async {
          final t = _txt.text.trim();
          if (t.isEmpty) return;
          _txt.clear();
          final m = MessageModel(
                  id: const Uuid().v4(),
                  roomId: widget.room.id,
                  senderId: StorageService.getDeviceId(),
                  senderNick: StorageService.getNickname() ?? 'User',
                  text: t,
                  createdAt: DateTime.now(),
                  expiresAt: DateTime.now().add(_ttl),
                  messageType: 'text',
                  recipientId: _privateToId,
                );
          _box.add(m);
          widget.nearby.sendMessage(m);
          setState(() { _privateToId = null; _privateToNick = null; });
          _bottom();
    }

    // ── Enviar imagem ───────────────────────────────────────────────────────────
    Future<void> _img() async {
          final xf = await _picker.pickImage(
                    source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 60);
          if (xf == null) return;
          final m = MessageModel(
                  id: const Uuid().v4(),
                  roomId: widget.room.id,
                  senderId: StorageService.getDeviceId(),
                  senderNick: StorageService.getNickname() ?? 'User',
                  text: '[Imagem]',
                  createdAt: DateTime.now(),
                  expiresAt: DateTime.now().add(_ttl),
                  messageType: 'image',
                  imagePath: xf.path,
                );
          _box.add(m);
          widget.nearby.sendMessage(m);
          _bottom();
    }

    // ── Iniciar gravacao de audio ────────────────────────────────────────────────
    Future<void> _startRecording() async {
          final hasPermission = await _recorder.hasPermission();
          if (!hasPermission) return;
          final dir = await getTemporaryDirectory();
          final path = p.join(dir.path, const Uuid().v4() + '.aac');
          await _recorder.start(
                  const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 22050),
                  path: path,
                );
          setState(() { _isRecording = true; _recSeconds = 0; });
          // Timer: incrementa segundo a segundo e para automaticamente em 10s
          _recTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
                  if (!mounted) { t.cancel(); return; }
                  setState(() => _recSeconds++);
                  if (_recSeconds >= _maxRecSeconds) {
                            t.cancel();
                            await _stopRecording();
                  }
          });
    }

    // ── Parar gravacao e enviar ─────────────────────────────────────────────────
    Future<void> _stopRecording() async {
          _recTimer?.cancel();
          _recTimer = null;
          if (!_isRecording) return;
          final path = await _recorder.stop();
          setState(() { _isRecording = false; _recSeconds = 0; });
          if (path == null) return;
          final m = MessageModel(
                  id: const Uuid().v4(),
                  roomId: widget.room.id,
                  senderId: StorageService.getDeviceId(),
                  senderNick: StorageService.getNickname() ?? 'User',
                  text: '[Audio]',
                  createdAt: DateTime.now(),
                  expiresAt: DateTime.now().add(_ttl),
                  messageType: 'audio',
                  audioPath: path,
                  recipientId: _privateToId,
                );
          _box.add(m);
          widget.nearby.sendMessage(m);
          setState(() { _privateToId = null; _privateToNick = null; });
          _bottom();
    }

    // ── Cancelar gravacao ───────────────────────────────────────────────────────
    Future<void> _cancelRecording() async {
          _recTimer?.cancel();
          _recTimer = null;
          if (!_isRecording) return;
          await _recorder.stop();
          setState(() { _isRecording = false; _recSeconds = 0; });
    }

    Future<void> _playAudio(String path) async {
          try { await _player.setFilePath(path); await _player.play(); } catch (_) {}
    }

    // ── Selecionar destinatario privado ─────────────────────────────────────────
    void _selectRecipient(BuildContext ctx) {
          final myId = StorageService.getDeviceId();
          final seen = <String>{};
          final senders = _msgs
                    .where((m) => m.senderId != myId && seen.add(m.senderId))
                    .map((m) => MapEntry(m.senderId, m.senderNick))
                    .toList();
          showModalBottomSheet(
                  context: ctx,
                  backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(height: 12),
                            Container(width: 40, height: 4,
                                                  decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(height: 16),
                            const Text('Enviar mensagem para:',
                                                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ListTile(
                                        leading: const CircleAvatar(backgroundColor: AppTheme.primary,
                                                                                  child: Icon(Icons.public, color: Colors.black, size: 18)),
                                        title: const Text('Todos (mensagem publica)'),
                                        onTap: () {
                                                      setState(() { _privateToId = null; _privateToNick = null; });
                                                      Navigator.pop(ctx);
                                        },
                                      ),
                            if (senders.isEmpty)
                              const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text('Nenhum outro usuario na sala ainda.',
                                                                        style: TextStyle(color: AppTheme.textSecondary)),
                                          )
                            else
                              ...senders.map((e) => ListTile(
                                            leading: CircleAvatar(
                                                            backgroundColor: Colors.orange.withOpacity(0.2),
                                                            child: const Icon(Icons.person, color: Colors.orange, size: 18),
                                                          ),
                                            title: Text(e.value),
                                            subtitle: const Text('Mensagem privada',
                                                                                 style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                            trailing: const Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                                            onTap: () {
                                                            setState(() { _privateToId = e.key; _privateToNick = e.value; });
                                                            Navigator.pop(ctx);
                                            },
                                          )),
                            const SizedBox(height: 16),
                          ]),
                );
    }

    void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
                  _scroll.animateTo(_scroll.position.maxScrollExtent,
                                              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
          }
    });

    @override
    void dispose() {
          _txt.dispose();
          _scroll.dispose();
          _recTimer?.cancel();
          _recorder.dispose();
          _player.dispose();
          widget.nearby.onMessageReceived = null;
          super.dispose();
    }

    // ── Botao mic com contador ───────────────────────────────────────────────────
    Widget _buildMicButton() {
          if (_isRecording) {
                  // Mostra contador + botao de parar e cancelar
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                            // Cancelar
                            GestureDetector(
                                        onTap: _cancelRecording,
                                        child: const CircleAvatar(
                                                      backgroundColor: Colors.grey,
                                                      radius: 20,
                                                      child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                                    ),
                                      ),
                            const SizedBox(width: 8),
                            // Contador
                            Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                                                    ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                      const Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                                      '$_recSeconds/${_maxRecSeconds}s',
                                                                      style: const TextStyle(
                                                                                          fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                                                                    ),
                                                    ]),
                                      ),
                            const SizedBox(width: 8),
                            // Enviar (parar)
                            GestureDetector(
                                        onTap: _stopRecording,
                                        child: const CircleAvatar(
                                                      backgroundColor: Colors.red,
                                                      radius: 20,
                                                      child: Icon(Icons.stop, color: Colors.white, size: 20),
                                                    ),
                                      ),
                          ]);
          }

          // Nao gravando: mic (toque para iniciar) ou send
          if (_txt.text.trim().isEmpty) {
                  return GestureDetector(
                            onTap: _startRecording,
                            child: const CircleAvatar(
                                        backgroundColor: AppTheme.primary,
                                        radius: 20,
                                        child: Icon(Icons.mic_none, color: Colors.black, size: 20),
                                      ),
                          );
          }

          return CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  radius: 20,
                  child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.black, size: 18),
                              onPressed: _send),
                );
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  appBar: AppBar(
                            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(widget.room.name,
                                                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(
                                                      widget.room.messageTtlHours < 8760
                                                          ? 'Msgs expiram em ${widget.room.messageTtlHours}h'
                                                          : 'Mensagens permanentes',
                                                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                                    ),
                                      ]),
                          ),
                  body: Column(children: [
                            // Status conexao
                            StreamBuilder<String>(
                                        stream: widget.nearby.statusStream,
                                        initialData: 'Iniciando...',
                                        builder: (_, s) => Container(
                                                      color: AppTheme.primary.withOpacity(0.8),
                                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                                      child: Row(children: [
                                                                      const Icon(Icons.wifi, size: 14, color: Colors.white),
                                                                      const SizedBox(width: 6),
                                                                      Expanded(child: Text(s.data!,
                                                                                                             style: const TextStyle(fontSize: 11, color: Colors.white))),
                                                                    ]),
                                                    ),
                                      ),
                            // Banner de mensagem privada ativa
                            if (_privateToNick != null)
                              Container(
                                            color: Colors.orange.withOpacity(0.15),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                            child: Row(children: [
                                                            const Icon(Icons.lock_outline, size: 14, color: Colors.orange),
                                                            const SizedBox(width: 6),
                                                            Expanded(
                                                                              child: Text(
                                                                                                  'Privado para: $_privateToNick',
                                                                                                  style: const TextStyle(
                                                                                                                          fontSize: 12,
                                                                                                                          color: Colors.orange,
                                                                                                                          fontWeight: FontWeight.w600),
                                                                                                ),
                                                                            ),
                                                            IconButton(
                                                                              icon: const Icon(Icons.close, size: 16),
                                                                              onPressed: () =>
                                                                                  setState(() { _privateToId = null; _privateToNick = null; }),
                                                                            ),
                                                          ]),
                                          ),
                            // Lista de mensagens
                            Expanded(
                                        child: ValueListenableBuilder(
                                                      valueListenable: _box.listenable(),
                                                      builder: (_, __, ___) {
                                                                      final msgs = _msgs;
                                                                      if (msgs.isEmpty) {
                                                                                        return const Center(
                                                                                                            child: Text('Sem mensagens. Seja o primeiro!',
                                                                                                                                              style: TextStyle(color: AppTheme.textSecondary)),
                                                                                                          );
                                                                      }
                                                                      return ListView.builder(
                                                                                        controller: _scroll,
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                                        itemCount: msgs.length,
                                                                                        itemBuilder: (_, i) {
                                                                                                            final m = msgs[i];
                                                                                                            final isMe = m.senderId == StorageService.getDeviceId();
                                                                                                            if (m.isAudio) return _buildAudioBubble(m, isMe);
                                                                                                            return MessageBubble(
                                                                                                                                  message: m,
                                                                                                                                  isMe: isMe,
                                                                                                                                  onPrivateReply: isMe
                                                                                                                                      ? null
                                                                                                                                      : () => setState(() {
                                                                                                                                                                      _privateToId = m.senderId;
                                                                                                                                                                      _privateToNick = m.senderNick;
                                                                                                                                      }),
                                                                                                                                );
                                                                                        },
                                                                                      );
                                                      },
                                                    ),
                                      ),
                            // Barra de entrada
                            Container(
                                        color: AppTheme.surface,
                                        padding: const EdgeInsets.fromLTRB(4, 8, 8, 16),
                                        child: Row(children: [
                                                      if (!_isRecording) ...[
                                                                      IconButton(
                                                                                        icon: const Icon(Icons.image_outlined),
                                                                                        onPressed: _img,
                                                                                        color: AppTheme.textSecondary,
                                                                                      ),
                                                                      IconButton(
                                                                                        icon: Icon(
                                                                                                            _privateToNick != null ? Icons.lock : Icons.person_outline,
                                                                                                          ),
                                                                                        onPressed: () => _selectRecipient(context),
                                                                                        color: _privateToNick != null ? Colors.orange : AppTheme.textSecondary,
                                                                                        tooltip: 'Mensagem privada',
                                                                                      ),
                                                                      Expanded(
                                                                                        child: TextField(
                                                                                                            controller: _txt,
                                                                                                            maxLines: null,
                                                                                                            textInputAction: TextInputAction.send,
                                                                                                            onSubmitted: (_) => _send(),
                                                                                                            onChanged: (_) => setState(() {}),
                                                                                                            decoration: const InputDecoration(
                                                                                                                                  hintText: 'Mensagem...',
                                                                                                                                  contentPadding:
                                                                                                                                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                                                                                                ),
                                                                                                          ),
                                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                    ],
                                                      _buildMicButton(),
                                                    ]),
                                      ),
                          ]),
                );
    }

    // ── Bubble de audio ─────────────────────────────────────────────────────────
    Widget _buildAudioBubble(MessageModel m, bool isMe) {
          return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                        color: isMe ? AppTheme.primary.withOpacity(0.85) : AppTheme.surfaceLight,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                            child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                                      // Nome + badge privado
                                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                                                      Text(
                                                                                        isMe ? 'Voce' : m.senderNick,
                                                                                        style: TextStyle(
                                                                                                              fontSize: 11,
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                              color: isMe ? Colors.black87 : AppTheme.primary),
                                                                                      ),
                                                                      if (m.isPrivate) ...[
                                                                                        const SizedBox(width: 4),
                                                                                        Container(
                                                                                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                                                                            decoration: BoxDecoration(
                                                                                                                                  color: Colors.orange.withOpacity(0.25),
                                                                                                                                  borderRadius: BorderRadius.circular(6),
                                                                                                                                ),
                                                                                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                                                                                                                  Icon(Icons.lock_outline, size: 9, color: Colors.orange),
                                                                                                                                  SizedBox(width: 2),
                                                                                                                                  Text('privado',
                                                                                                                                                               style: TextStyle(
                                                                                                                                                                                             fontSize: 9,
                                                                                                                                                                                             color: Colors.orange,
                                                                                                                                                                                             fontWeight: FontWeight.bold)),
                                                                                                                                ]),
                                                                                                          ),
                                                                                      ],
                                                                    ]),
                                                      const SizedBox(height: 4),
                                                      // Player de audio
                                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                                                      const Icon(Icons.graphic_eq, size: 18),
                                                                      const SizedBox(width: 4),
                                                                      GestureDetector(
                                                                                        onTap: () { if (m.audioPath != null) _playAudio(m.audioPath!); },
                                                                                        child: const Icon(Icons.play_circle, size: 32, color: AppTheme.primary),
                                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      const Text('Toque para ouvir', style: TextStyle(fontSize: 10)),
                                                                    ]),
                                                    ],
                                      ),
                          ),
                );
    }
}
