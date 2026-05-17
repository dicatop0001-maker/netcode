import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/room_model.dart';
import '../services/storage_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});
  @override State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _nameCtrl = TextEditingController();
  RoomType _type = RoomType.bairro;
  String? _qr, _id, _name;
  bool _isCreator = false;

  void _generate() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final id = const Uuid().v4().substring(0, 12);
    final name = _nameCtrl.text.trim();
    final qr = 'mesh://${_type.name}-$id';
    final room = RoomModel(
      id: id, name: name, type: _type.name, qrData: qr, createdAt: DateTime.now(),
      creatorId: StorageService.getDeviceId(),
    );
    StorageService.saveRoom(room);
    setState(() { _qr = qr; _id = id; _name = name; _isCreator = true; });
  }

  void _deleteRoom() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar Sala?'),
        content: Text('Tem certeza que deseja apagar a sala "$_name"? Esta acao nao pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (_id != null) StorageService.deleteRoom(_id!);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sala apagada com sucesso!')));
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editRoomName() {
    final editCtrl = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Nome da Sala'),
        content: TextField(
          controller: editCtrl,
          decoration: const InputDecoration(
            labelText: 'Novo nome da sala',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final newName = editCtrl.text.trim();
              if (newName.isEmpty) return;
              if (_id != null) {
                final room = StorageService.getRoom(_id!);
                if (room != null) {
                  final updated = RoomModel(
                    id: room.id, name: newName, type: room.type,
                    qrData: room.qrData, createdAt: room.createdAt,
                    creatorId: room.creatorId, description: room.description,
                  );
                  StorageService.saveRoom(updated);
                }
              }
              setState(() { _name = newName; _nameCtrl.text = newName; });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nome da sala atualizado!')));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _shareRoom() {
    if (_qr == null) return;
    final link = 'netcode://sala/$_id';
    Share.share('Entre na sala "$_name" no Netcode!\n\nLink: $link\n\nQR Data: $_qr');
  }

  void _copyLink() {
    if (_id == null) return;
    final link = 'netcode://sala/$_id';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado!')));
  }

  @override void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sala'),
        actions: [
          if (_qr != null && _isCreator) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: 'Editar Nome da Sala',
              onPressed: _editRoomName,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Apagar Sala',
              onPressed: _deleteRoom,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tipo de ambiente', style: TextStyle(fontWeight: FontWeight.w600,
            fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal,
            children: RoomType.values.map((t) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${t.emoji} ${t.label}'), selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: _type == t ? Colors.black : AppTheme.textPrimary, fontSize: 12)),
            )).toList())),
          const SizedBox(height: 16),
          // Botao criar ambiente especifico
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.add_location_alt_outlined, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Criar Ambiente', style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.primary)),
              ]),
              const SizedBox(height: 4),
              const Text(
                'Crie um ambiente especifico: manifestacao na avenida, show, feira, emergencia e muito mais.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                RoomType.protesto, RoomType.evento, RoomType.show,
                RoomType.emergencia, RoomType.feira, RoomType.carnaval,
              ].map((t) => ActionChip(
                avatar: Text(t.emoji),
                label: Text(t.label, style: const TextStyle(fontSize: 11)),
                backgroundColor: _type == t ? AppTheme.primary : null,
                labelStyle: TextStyle(
                  color: _type == t ? Colors.black : AppTheme.textPrimary),
                onPressed: () => setState(() => _type = t),
              )).toList()),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(
            labelText: 'Nome da sala',
            hintText: 'Ex: Bairro Centro, Show Rock...',
            prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text('Gerar QR Code'), onPressed: _generate)),
          if (_qr != null) ...[
            const SizedBox(height: 32),
            Center(child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_isCreator) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _editRoomName,
                    child: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text('${_type.emoji} ${_type.label}',
                style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: _qr!, version: QrVersions.auto,
                  size: 220, backgroundColor: Colors.white)),
              const SizedBox(height: 12),
              Text(_qr!, style: const TextStyle(fontSize: 11,
                color: AppTheme.textSecondary, fontFamily: 'monospace')),
              const SizedBox(height: 16),
              // Botoes de compartilhamento (qualquer membro da sala pode usar)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                  onPressed: _shareRoom),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Copiar Link'),
                  onPressed: _copyLink),
              ]),
              const SizedBox(height: 8),
              const Text('Qualquer membro pode compartilhar o QR Code ou link',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
              if (_isCreator) ...[
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      foregroundColor: Colors.blue),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar Nome'),
                    onPressed: _editRoomName),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Apagar Sala'),
                    onPressed: _deleteRoom),
                ]),
                const SizedBox(height: 4),
                const Text('Apenas o criador pode editar ou apagar a sala',
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ])),
          ],
        ])));
  }
}
