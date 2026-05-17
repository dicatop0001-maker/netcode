import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/room_model.dart';
import '../services/storage_service.dart';
import '../services/nearby_service.dart';
import '../screens/chat_screen.dart';

class RoomListWidget extends StatefulWidget {
  final NearbyService nearby;
  const RoomListWidget({super.key, required this.nearby});
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
        const Text('Escaneie ou crie um QR Code\npara entrar na rede local.',
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
          // Tenta mapear o tipo para emoji; se nao encontrar usa o description como label
          final t = RoomType.values.where((t) => t.name == r.type).firstOrNull;
          final emoji = t?.emoji ?? '\u{1F4E1}';
          final label = t?.label ?? r.type;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))),
              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Row(children: [
                  const Icon(Icons.chat_bubble_outline, size: 11, color: AppTheme.primary),
                  const SizedBox(width: 3),
                  const Text('Toque para abrir o chat',
                    style: TextStyle(fontSize: 10, color: AppTheme.primary,
                      fontStyle: FontStyle.italic)),
                ]),
              ]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                StorageService.setCurrentRoom(r);
                widget.nearby.joinRoom(r);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(room: r, nearby: widget.nearby)));
              },
            ),
          );
        },
      ),
    );
  }
}
