import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/room_model.dart';
import '../services/nearby_service.dart';
import '../services/storage_service.dart';
import 'chat_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final NearbyService nearby;
  const QrScannerScreen({super.key, required this.nearby});
  @override State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _ctrl = MobileScannerController();
  bool _scanned = false;

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onDetect(BarcodeCapture c) {
    if (_scanned) return;
    final v = c.barcodes.firstOrNull?.rawValue;
    if (v == null || !v.startsWith('mesh://')) return;
    _scanned = true;
    _ctrl.stop();
    _join(v);
  }

  void _join(String qr) {
    final parts = qr.replaceFirst('mesh://', '').split('-');
    final type = parts.isNotEmpty ? parts[0] : 'geral';
    final id = parts.length > 1 ? parts.sublist(1).join('-') : const Uuid().v4().substring(0, 8);
    RoomModel? room = StorageService.getRoom(id);
    if (room == null) {
      room = RoomModel(id: id, name: '${_label(type)} Local',
          type: type, qrData: qr, createdAt: DateTime.now());
      StorageService.saveRoom(room);
    }
    widget.nearby.joinRoom(room);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ChatScreen(room: room!, nearby: widget.nearby)));
  }

  String _label(String t) {
    try { return RoomType.values.firstWhere((r) => r.name == t).label; }
    catch (_) { return 'Sala'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _ctrl.torchState,
              builder: (_, s, __) =>
                  Icon(s == TorchState.on ? Icons.flash_on : Icons.flash_off)),
            onPressed: _ctrl.toggleTorch),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _ctrl, onDetect: _onDetect),
        Center(child: Container(width: 260, height: 260,
            decoration: BoxDecoration(border: Border.all(color: AppTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(16)))),
        Positioned(bottom: 60, left: 0, right: 0,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.black54,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Aponte para o QR Code da sala',
                style: TextStyle(color: Colors.white, fontSize: 14))))),
      ]),
    );
  }
}
