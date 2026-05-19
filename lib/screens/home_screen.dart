import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/nearby_service.dart';
import '../widgets/room_list_widget.dart';
import '../widgets/room_management_sheet.dart';
import '../models/room_model.dart';
import 'qr_scanner_screen.dart';
import 'qr_generator_screen.dart';
import 'marketplace_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import 'event_screen.dart';

class HomeScreen extends StatefulWidget {
    const HomeScreen({super.key});
    @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    int _tab = 0;
    final NearbyService _nearby = NearbyService();
    final GlobalKey<RoomListWidgetState> _roomListKey = GlobalKey<RoomListWidgetState>();

    @override void initState() { super.initState(); _nearby.init(); }
    @override void dispose() { _nearby.stop(); super.dispose(); }

    void _openRoom(RoomModel room) {
          StorageService.setCurrentRoom(room);
          _nearby.joinRoom(room);
          Navigator.push(context, MaterialPageRoute(
                  builder: (_) => room.isEvent
                    ? EventScreen(room: room, nearby: _nearby)
                    : ChatScreen(room: room, nearby: _nearby)));
    }

    @override
    Widget build(BuildContext context) {
          return Scaffold(
                  appBar: AppBar(
                            title: const Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(Icons.wifi_tethering_rounded, color: AppTheme.primary, size: 22),
                                        SizedBox(width: 8),
                                        Text('netcode', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 20)),
                                      ]),
                            actions: [
                                        StreamBuilder<int>(
                                                      stream: _nearby.peerCountStream, initialData: 0,
                                                      builder: (_, s) => Padding(
                                                                      padding: const EdgeInsets.only(right: 4),
                                                                      child: Chip(
                                                                                        label: Text(s.data.toString() + ' online',
                                                                                                                      style: const TextStyle(fontSize: 11, color: Colors.black)),
                                                                                        backgroundColor: s.data! > 0 ? AppTheme.primary : AppTheme.surfaceLight,
                                                                                        padding: EdgeInsets.zero))),
                                        IconButton(
                                                      icon: const Icon(Icons.settings_outlined),
                                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                                      ],
                          ),
                  body: IndexedStack(index: _tab, children: [
                            RoomListWidget(key: _roomListKey, nearby: _nearby, onRoomTap: _openRoom),
                            const MarketplaceScreen(),
                          ]),
                  floatingActionButton: FloatingActionButton.extended(
                            onPressed: () => _joinOptions(context),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Entrar/Criar Sala')),
                  bottomNavigationBar: NavigationBar(
                            backgroundColor: AppTheme.surface,
                            selectedIndex: _tab,
                            onDestinationSelected: (i) => setState(() => _tab = i),
                            destinations: const [
                                        NavigationDestination(icon: Icon(Icons.chat_bubble_outline),
                                                                          selectedIcon: Icon(Icons.chat_bubble), label: 'Salas'),
                                        NavigationDestination(icon: Icon(Icons.storefront_outlined),
                                                                          selectedIcon: Icon(Icons.storefront), label: 'Compra e Venda Local'),
                                      ],
                          ),
                );
    }

    void _joinOptions(BuildContext ctx) {
          showModalBottomSheet(
                  context: ctx, backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                                        Container(width: 40, height: 4, decoration: BoxDecoration(
                                                      color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2))),
                                        const SizedBox(height: 20),
                                        const Text('Entrar ou Criar Sala', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 20),
                                        _Tile(
                                                      icon: Icons.qr_code_scanner, title: 'Escanear QR Code',
                                                      sub: 'Entrar em sala existente',
                                                      onTap: () {
                                                                      Navigator.pop(ctx);
                                                                      Navigator.push(ctx, MaterialPageRoute(builder: (_) => QrScannerScreen(nearby: _nearby)));
                                                      }),
                                        const SizedBox(height: 12),
                                        _Tile(
                                                      icon: Icons.add_circle_outline, title: 'Criar nova sala',
                                                      sub: 'Sala de chat ou evento com QR Code',
                                                      onTap: () async {
                                                                      Navigator.pop(ctx);
                                                                      final room = await Navigator.push<RoomModel>(ctx,
                                                                                                                                   MaterialPageRoute(builder: (_) => const QrGeneratorScreen()));
                                                                      if (room != null && mounted) {
                                                                                        _roomListKey.currentState?.reload();
                                                                                        setState(() => _tab = 0);
                                                                                        // Abre sheet de gerenciamento para o criador compartilhar/apagar
                                                                                        await RoomManagementSheet.show(
                                                                                                            ctx,
                                                                                                            room: room,
                                                                                                            onDeleted: () {
                                                                                                                                  _roomListKey.currentState?.reload();
                                                                                                                                  setState(() {});
                                                                                                            },
                                                                                                          );
                                                                                        // Entra na sala somente se ela ainda existir
                                                                                        if (StorageService.getRoom(room.id) != null && mounted) {
                                                                                                            _openRoom(room);
                                                                                        }
                                                                      }
                                                      }),
                                        const SizedBox(height: 20),
                                      ])));
    }
}

class _Tile extends StatelessWidget {
    final IconData icon; final String title, sub; final VoidCallback onTap;
    const _Tile({required this.icon, required this.title, required this.sub, required this.onTap});
    @override
    Widget build(BuildContext context) => ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: AppTheme.surfaceLight,
          leading: Container(width: 44, height: 44,
                                   decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                   child: Icon(icon, color: AppTheme.primary)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          onTap: onTap);
}
