import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/room_model.dart';
import '../services/storage_service.dart';
import '../services/nearby_service.dart';
import 'room_management_sheet.dart';

class RoomListWidget extends StatefulWidget {
    final NearbyService nearby;
    final void Function(RoomModel)? onRoomTap;
    const RoomListWidget({super.key, required this.nearby, this.onRoomTap});
    @override State<RoomListWidget> createState() => RoomListWidgetState();
}

class RoomListWidgetState extends State<RoomListWidget> {
    List<RoomModel> _rooms = [];

    @override void initState() { super.initState(); reload(); }

    void reload() => setState(() => _rooms = StorageService.getAllRooms());

    @override
    Widget build(BuildContext context) {
          if (_rooms.isEmpty) return Center(child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.wifi_tethering_outlined, size: 60, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            const Text('Nenhuma sala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Escaneie ou crie um QR Code para entrar na rede local.',
                                                   textAlign: TextAlign.center,
                                                   style: TextStyle(color: AppTheme.textSecondary)),
                          ]));

          return RefreshIndicator(
                  onRefresh: () async => reload(),
                  child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _rooms.length,
                            itemBuilder: (_, i) {
                                        final r = _rooms[i];
                                        final t = RoomType.values.where((t) => t.name == r.type).firstOrNull;
                                        final emoji = r.isEvent ? '\u{1F3AA}' : (t?.emoji ?? '\u{1F4E1}');
                                        final label = t?.label ?? r.type;
                                        final isCreator = StorageService.isRoomCreator(r.id);
                                        return Card(
                                                      margin: const EdgeInsets.only(bottom: 8),
                                                      child: ListTile(
                                                                      leading: Container(
                                                                                        width: 44, height: 44,
                                                                                        decoration: BoxDecoration(
                                                                                                            color: r.isEvent
                                                                                                              ? Colors.orange.withOpacity(0.15)
                                                                                                              : AppTheme.primary.withOpacity(0.15),
                                                                                                            borderRadius: BorderRadius.circular(10)),
                                                                                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))),
                                                                      title: Row(children: [
                                                                                        Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                                                                        if (r.isEvent)
                                                                                          Container(
                                                                                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                                                                decoration: BoxDecoration(
                                                                                                                                        color: Colors.orange.withOpacity(0.2),
                                                                                                                                        borderRadius: BorderRadius.circular(8)),
                                                                                                                child: const Text('EVENTO',
                                                                                                                                                        style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold))),
                                                                                        if (isCreator) ...[
                                                                                                            const SizedBox(width: 4),
                                                                                                            Container(
                                                                                                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                                                                                                  decoration: BoxDecoration(
                                                                                                                                                          color: AppTheme.primary.withOpacity(0.15),
                                                                                                                                                          borderRadius: BorderRadius.circular(6)),
                                                                                                                                  child: const Text('Criador',
                                                                                                                                                                          style: TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.bold))),
                                                                                                          ],
                                                                                      ]),
                                                                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                                                        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                                                                        Row(children: [
                                                                                                            Icon(r.isEvent ? Icons.event : Icons.chat_bubble_outline,
                                                                                                                                     size: 11, color: AppTheme.primary),
                                                                                                            const SizedBox(width: 3),
                                                                                                            Text(r.isEvent ? 'Toque para ver o evento' : 'Toque para abrir o chat',
                                                                                                                                     style: const TextStyle(
                                                                                                                                                             fontSize: 10, color: AppTheme.primary, fontStyle: FontStyle.italic)),
                                                                                                          ]),
                                                                                      ]),
                                                                      trailing: isCreator
                                                                        ? IconButton(
                                                                                              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                                                                                              tooltip: 'Gerenciar sala',
                                                                                              onPressed: () => RoomManagementSheet.show(
                                                                                                                      context,
                                                                                                                      room: r,
                                                                                                                      onDeleted: reload,
                                                                                                                    ),
                                                                                            )
                                                                        : const Icon(Icons.chevron_right),
                                                                      onTap: () {
                                                                                        if (widget.onRoomTap != null) widget.onRoomTap!(r);
                                                                      },
                                                                    ),
                                                    );
                            },
                          ),
                );
    }
}
