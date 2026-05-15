import 'package:flutter/material.dart';
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

  void _generate() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final id = const Uuid().v4().substring(0, 12);
    final name = _nameCtrl.text.trim();
    final qr = 'mesh://${_type.name}-$id';
    StorageService.saveRoom(RoomModel(
        id: id, name: name, type: _type.name, qrData: qr, createdAt: DateTime.now()));
    setState(() { _qr = qr; _id = id; _name = name; });
  }

  @override void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Sala')),
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
          const SizedBox(height: 20),
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
              Text(_name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
              ElevatedButton.icon(icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
                onPressed: () => Share.share(
                    'Entre na sala "$_name" no Netcode!\n\n$_qr')),
            ])),
          ],
        ])));
  }
}
