import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/room_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RoomManagementSheet extends StatelessWidget {
    final RoomModel room;
    final VoidCallback onDeleted;

    const RoomManagementSheet({
          super.key,
          required this.room,
          required this.onDeleted,
    });

    static Future<void> show(
          BuildContext context, {
                required RoomModel room,
                required VoidCallback onDeleted,
          }) {
          return showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                  builder: (_) => RoomManagementSheet(room: room, onDeleted: onDeleted),
                );
    }

    @override
    Widget build(BuildContext context) {
          final isCreator = StorageService.isRoomCreator(room.id);
          return DraggableScrollableSheet(
                  initialChildSize: 0.75,
                  minChildSize: 0.5,
                  maxChildSize: 0.92,
                  expand: false,
                  builder: (_, controller) => SingleChildScrollView(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                            child: Column(children: [
                                        Container(
                                                      width: 40, height: 4,
                                                      decoration: BoxDecoration(
                                                                      color: AppTheme.surfaceLight,
                                                                      borderRadius: BorderRadius.circular(2),
                                                                    ),
                                                    ),
                                        const SizedBox(height: 20),
                                        Row(children: [
                                                      Container(
                                                                      width: 48, height: 48,
                                                                      decoration: BoxDecoration(
                                                                                        color: AppTheme.primary.withOpacity(0.15),
                                                                                        borderRadius: BorderRadius.circular(12),
                                                                                      ),
                                                                      child: const Icon(Icons.meeting_room_outlined,
                                                                                                          color: AppTheme.primary, size: 26),
                                                                    ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                      children: [
                                                                                                                        Text(room.name,
                                                                                                                                                 style: const TextStyle(
                                                                                                                                                                           fontSize: 18, fontWeight: FontWeight.bold)),
                                                                                                                        Text(room.type,
                                                                                                                                                 style: const TextStyle(
                                                                                                                                                                           fontSize: 13, color: AppTheme.textSecondary)),
                                                                                                                      ]),
                                                                    ),
                                                      if (isCreator)
                                                        Container(
                                                                          padding:
                                                                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                          decoration: BoxDecoration(
                                                                                              color: AppTheme.primary.withOpacity(0.15),
                                                                                              borderRadius: BorderRadius.circular(8),
                                                                                            ),
                                                                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                                                                              Icon(Icons.star, size: 12, color: AppTheme.primary),
                                                                                              SizedBox(width: 4),
                                                                                              Text('Criador',
                                                                                                                         style: TextStyle(
                                                                                                                                                     fontSize: 11,
                                                                                                                                                     color: AppTheme.primary,
                                                                                                                                                     fontWeight: FontWeight.bold)),
                                                                                            ]),
                                                                        ),
                                                    ]),
                                        const SizedBox(height: 24),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        _QrCodeSection(room: room),
                                        if (isCreator) ...[
                                                      const SizedBox(height: 24),
                                                      const Divider(),
                                                      const SizedBox(height: 16),
                                                      _DeleteSection(
                                                                        room: room,
                                                                        onDeleted: () {
                                                                                            Navigator.pop(context);
                                                                                            onDeleted();
                                                                        }),
                                                    ],
                                      ]),
                          ),
                );
    }
}

class _QrCodeSection extends StatefulWidget {
    final RoomModel room;
    const _QrCodeSection({required this.room});
    @override
    State<_QrCodeSection> createState() => _QrCodeSectionState();
}

class _QrCodeSectionState extends State<_QrCodeSection> {
    final GlobalKey _qrKey = GlobalKey();
    bool _sharing = false;

    Future<void> _shareQr() async {
          if (_sharing) return;
          setState(() => _sharing = true);
          try {
                  final boundary = _qrKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?;
                  if (boundary == null) return;
                  final image = await boundary.toImage(pixelRatio: 3.0);
                  final byteData =
                              await image.toByteData(format: ui.ImageByteFormat.png);
                  if (byteData == null) return;
                  final pngBytes = byteData.buffer.asUint8List();
                  final xFile = XFile.fromData(pngBytes,
                                                         name: 'sala_${widget.room.id}.png', mimeType: 'image/png');
                  await Share.shareXFiles(
                            [xFile],
                            text:
                                'Entre na sala "${widget.room.name}" no netcode!\nLink: ${widget.room.qrData}',
                            subject: 'Sala netcode - ${widget.room.name}',
                          );
          } catch (e) {
                  if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Erro ao compartilhar: $e')));
                  }
          } finally {
                  if (mounted) setState(() => _sharing = false);
          }
    }

    Future<void> _copyLink() async {
          await Clipboard.setData(ClipboardData(text: widget.room.qrData));
          if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                        content: Text('Link copiado para a area de transferencia!'),
                                        duration: Duration(seconds: 2),
                                      ),
                          );
          }
    }

    @override
    Widget build(BuildContext context) {
          return Column(children: [
                  const Text('QR Code da Sala',
                                       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Mostre este QR para outras pessoas entrarem',
                                       style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                       textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(20),
                                                      boxShadow: [
                                                                      BoxShadow(
                                                                                          color: Colors.black.withOpacity(0.12),
                                                                                          blurRadius: 20,
                                                                                          offset: const Offset(0, 4))
                                                                    ],
                                                    ),
                                        child: Column(children: [
                                                      QrImageView(
                                                                      data: widget.room.qrData,
                                                                      version: QrVersions.auto,
                                                                      size: 200,
                                                                      backgroundColor: Colors.white,
                                                                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                                                                    ),
                                                      const SizedBox(height: 8),
                                                      Text(widget.room.name,
                                                                           style: const TextStyle(
                                                                                                 fontWeight: FontWeight.bold,
                                                                                                 fontSize: 13,
                                                                                                 color: Colors.black87)),
                                                      Text(widget.room.type,
                                                                           style:
                                                                               const TextStyle(fontSize: 11, color: Colors.black54)),
                                                    ]),
                                      ),
                          ),
                  const SizedBox(height: 16),
                  Row(children: [
                            Expanded(
                                        child: OutlinedButton.icon(
                                                      icon: const Icon(Icons.copy_outlined, size: 18),
                                                      label: const Text('Copiar Link'),
                                                      onPressed: _copyLink,
                                                      style: OutlinedButton.styleFrom(
                                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                                      foregroundColor: AppTheme.primary,
                                                                      side: const BorderSide(color: AppTheme.primary),
                                                                      shape: RoundedRectangleBorder(
                                                                                          borderRadius: BorderRadius.circular(12)),
                                                                    ),
                                                    ),
                                      ),
                            const SizedBox(width: 12),
                            Expanded(
                                        child: ElevatedButton.icon(
                                                      icon: _sharing
                                                          ? const SizedBox(
                                                                                width: 16,
                                                                                height: 16,
                                                                                child: CircularProgressIndicator(
                                                                                                          strokeWidth: 2, color: Colors.black))
                                                          : const Icon(Icons.share_outlined, size: 18),
                                                      label: const Text('Compartilhar'),
                                                      onPressed: _sharing ? null : _shareQr,
                                                      style: ElevatedButton.styleFrom(
                                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                                      textStyle:
                                                                          const TextStyle(fontWeight: FontWeight.w600),
                                                                      shape: RoundedRectangleBorder(
                                                                                          borderRadius: BorderRadius.circular(12)),
                                                                    ),
                                                    ),
                                      ),
                          ]),
                ]);
    }
}

class _DeleteSection extends StatelessWidget {
    final RoomModel room;
    final VoidCallback onDeleted;
    const _DeleteSection({required this.room, required this.onDeleted});

    Future<void> _confirmDelete(BuildContext context) async {
          final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                            title: const Text('Apagar sala?'),
                            content: Text(
                                          'Tem certeza que deseja apagar a sala "${room.name}"?\n\nTodas as mensagens locais serao removidas.'),
                            actions: [
                                        TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text('Cancelar'),
                                                    ),
                                        ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text('Apagar',
                                                                                        style: TextStyle(color: Colors.white)),
                                                    ),
                                      ],
                          ),
                );
          if (confirmed == true) {
                  await StorageService.deleteRoom(room.id);
                  onDeleted();
          }
    }

    @override
    Widget build(BuildContext context) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Zona de perigo',
                                       style: TextStyle(
                                                       fontWeight: FontWeight.w700,
                                                       fontSize: 13,
                                                       color: Colors.red)),
                  const SizedBox(height: 10),
                  SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: const Text('Apagar esta sala',
                                                                        style: TextStyle(
                                                                                            color: Colors.red, fontWeight: FontWeight.w600)),
                                        onPressed: () => _confirmDelete(context),
                                        style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      side: const BorderSide(color: Colors.red),
                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(12)),
                                                    ),
                                      ),
                          ),
                  const SizedBox(height: 8),
                  const Text(
                            'Apenas o criador pode apagar a sala.',
                            style:
                                TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                ]);
    }
}
