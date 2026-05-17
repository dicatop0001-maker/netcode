import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
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
  int _ttlHours = 24;
  bool _isEvent = false;
  bool _nameNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() {
      final notEmpty = _nameCtrl.text.trim().isNotEmpty;
      if (notEmpty != _nameNotEmpty) setState(() => _nameNotEmpty = notEmpty);
    });
  }

  void _generate() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final id = const Uuid().v4().substring(0, 12);
    final name = _nameCtrl.text.trim();
    final tipoLabel = _customAmbiente.trim().isNotEmpty ? _customAmbiente.trim() : 'Geral';
    final qr = 'https://netcode.app/sala/' + id;
    final room = RoomModel(
      id: id, name: name, type: tipoLabel,
      qrData: qr, createdAt: DateTime.now(),
      creatorId: StorageService.getDeviceId(),
      description: tipoLabel,
      messageTtlHours: _ttlHours,
      isEvent: _isEvent,
    );
    StorageService.saveRoom(room);
    Navigator.pop(context, room);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ambienteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Sala')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tipo de ambiente',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
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
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 12),
          ],
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
                Text('Criar Ambiente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.primary)),
              ]),
              const SizedBox(height: 4),
              const Text('Crie um ambiente especifico: manifestacao, show, feira, emergencia...',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: _ambienteCtrl,
                onChanged: (v) => setState(() => _customAmbiente = v),
                decoration: InputDecoration(
                  hintText: 'Ex: Manifestacao na Av. Paulista...',
                  labelText: 'Nome do ambiente',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _isEvent,
            onChanged: (v) => setState(() => _isEvent = v),
            title: const Text('Modo Evento', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Ativa mapa, horarios, avisos e setores', style: TextStyle(fontSize: 11)),
            secondary: const Icon(Icons.event, color: AppTheme.primary),
            tileColor: AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          const Text('Duracao das mensagens',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _TtlChip(label: '24h', value: 24, selected: _ttlHours == 24, onTap: () => setState(() => _ttlHours = 24)),
            _TtlChip(label: '48h', value: 48, selected: _ttlHours == 48, onTap: () => setState(() => _ttlHours = 48)),
            _TtlChip(label: '7 dias', value: 168, selected: _ttlHours == 168, onTap: () => setState(() => _ttlHours = 168)),
            _TtlChip(label: 'Sem limite', value: 8760, selected: _ttlHours == 8760, onTap: () => setState(() => _ttlHours = 8760)),
          ]),
          const SizedBox(height: 18),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome da sala *',
              hintText: 'Ex: Bairro Centro, Show Rock...',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 8),
          if (!_nameNotEmpty)
            const Text('Digite o nome da sala para continuar',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Gerar QR Code e Ir para Home'),
              onPressed: _nameNotEmpty ? _generate : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TtlChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;
  const _TtlChip({required this.label, required this.value, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
        style: TextStyle(
          color: selected ? Colors.black : AppTheme.textSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}
