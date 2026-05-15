import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'nickname_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final nick = StorageService.getNickname() ?? '---';
    final id = StorageService.getDeviceId();
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _S('Perfil'),
        Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: AppTheme.primary,
            child: Text(nick[0].toUpperCase(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
          title: Text(nick, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('ID: ${id.substring(0, 8)}...',
              style: const TextStyle(fontSize: 11)),
          trailing: IconButton(icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const NicknameScreen()))))),
        const SizedBox(height: 16),
        _S('Rede Mesh'),
        const Card(child: Column(children: [
          _I('Protocolo', 'Nearby Connections BT + Wi-Fi Direct'),
          _I('Estrategia', 'P2P Cluster (Mesh)'),
          _I('Alcance', '~100m por hop'),
          _I('Retransmissao', 'A -> B -> C -> D'),
        ])),
        const SizedBox(height: 16),
        _S('Dados'),
        Card(child: ListTile(
          leading: const Icon(Icons.delete_outline, color: AppTheme.error),
          title: const Text('Limpar dados expirados'),
          onTap: () {
            StorageService.cleanExpiredMessages();
            StorageService.cleanExpiredProducts();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dados expirados removidos')));
          })),
        const SizedBox(height: 16),
        _S('Sobre'),
        const Card(child: Column(children: [
          _I('App', 'Netcode v1.0.0'),
          _I('Missao', 'Rede local P2P sem internet'),
          _I('Armazenamento', 'Local - zero servidor'),
        ])),
      ]),
    );
  }
}

class _S extends StatelessWidget {
  final String t; const _S(this.t);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary, letterSpacing: 1)));
}

class _I extends StatelessWidget {
  final String l, v; const _I(this.l, this.v);
  @override Widget build(BuildContext context) => ListTile(dense: true,
    title: Text(l, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    trailing: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
}
