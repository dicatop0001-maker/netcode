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
  final _ambienteCtrl = TextEditingController();
  String _customAmbiente = '';
  String? _qr, _id, _name;
  bool _isCreator = false;
  bool _generated = false;

  void _generate() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final id = const Uuid().v4().substring(0, 12);
    final name = _nameCtrl.text.trim();
    final tipoLabel = _customAmbiente.trim().isNotEmpty
        ? _customAmbiente.trim()
        : 'Geral';
    final qr = 'mesh://custom-' + id;
    final room = RoomModel(
      id: id,
      name: name,
      type: tipoLabel,
      qrData: qr,
      createdAt: DateTime.now(),
      creatorId: StorageService.getDeviceId(),
      description: tipoLabel,
    );
    StorageService.saveRoom(room);
    setState(() {
      _qr = qr;
      _id = id;
      _name = name;
      _isCreator = true;
      _generated = true;
    });
    // Volta para a Home ja com a sala criada
    Navigator.pop(context, room);
  }

  void _deleteRoom() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar Sala?'),
        content: Text('Tem certeza que deseja apagar a sala "' + (_name ?? '') + '"?'),
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
    final link = 'netcode://sala/' + (_id ?? '');
    Share.share('Entre na sala "' + (_name ?? '') + '" no Netcode!\n\nLink: ' + link + '\n\nQR Data: ' + (_qr ?? ''));
  }

  void _copyLink() {
    if (_id == null) return;
    final link = 'netcode://sala/' + (_id ?? '');
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado!')));
  }

  @override void dispose() {
    _nameCtrl.dispose();
    _ambienteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Sala'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de ambiente - titulo
            const Text('Tipo de ambiente',
              style: TextStyle(fontWeight: FontWeight.w600,
                fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            // Nome do ambiente digitado aparece aqui
            if (_customAmbiente.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(_customAmbiente.trim(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            // Card Criar Ambiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.add_location_alt_outlined, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Criar Ambiente',
                    style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 15, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 4),
                const Text(
                  'Crie um ambiente especifico: manifestacao na avenida, show, feira, emergencia e muito mais.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ambienteCtrl,
                  onChanged: (v) => setState(() => _customAmbiente = v),
                  decoration: InputDecoration(
                    hintText: 'Ex: Manifestacao na Av. Paulista, Show de Rock...',
                    labelText: 'Nome do ambiente',
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da sala',
                hintText: 'Ex: Bairro Centro, Show Rock...',
                prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('Gerar QR Code e Ir para Home'),
                onPressed: _nameCtrl.text.trim().isNotEmpty ? _generate : null,
              ),
            ),
            const SizedBox(height: 8),
            // Ouvinte para habilitar botao ao digitar
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameCtrl,
              builder: (_, val, __) {
                return val.text.trim().isEmpty
                  ? const Center(
                      child: Text('Digite o nome da sala para continuar',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic)))
                  : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
