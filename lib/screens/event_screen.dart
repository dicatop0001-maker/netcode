import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/message_model.dart';
import '../models/room_model.dart';
import '../services/storage_service.dart';
import '../services/nearby_service.dart';

class EventScreen extends StatefulWidget {
  final RoomModel room;
  final NearbyService nearby;
  const EventScreen({super.key, required this.room, required this.nearby});
  @override State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _infoCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  late Box<MessageModel> _box;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _box = Hive.box<MessageModel>('messages');
  }

  @override void dispose() {
    _tabs.dispose(); _infoCtrl.dispose();
    _scheduleCtrl.dispose(); _sectorCtrl.dispose();
    super.dispose();
  }

  List<MessageModel> _msgs(String tag) {
    return _box.values.where((m) =>
      m.roomId == widget.room.id && !m.isExpired && m.text.startsWith('[' + tag + '] ')
    ).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _postMsg(String tag, String content) {
    if (content.trim().isEmpty) return;
    final m = MessageModel(
      id: const Uuid().v4(), roomId: widget.room.id,
      senderId: StorageService.getDeviceId(),
      senderNick: StorageService.getNickname() ?? 'User',
      text: '[' + tag + '] ' + content.trim(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(hours: widget.room.messageTtlHours)),
      messageType: 'text',
    );
    _box.add(m);
    widget.nearby.sendMessage(m);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('Modo Evento', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
        ]),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Info'),
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Mapa'),
            Tab(icon: Icon(Icons.schedule, size: 18), text: 'Horarios'),
            Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Avisos'),
            Tab(icon: Icon(Icons.emergency, size: 18), text: 'Emergencia'),
            Tab(icon: Icon(Icons.grid_view, size: 18), text: 'Setores'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _buildInfoTab(),
        _buildMapTab(),
        _buildScheduleTab(),
        _buildMsgTab('AVISO', 'Avisos e comunicados do evento', Icons.campaign, Colors.orange, _infoCtrl),
        _buildEmergencyTab(),
        _buildSectorTab(),
      ]),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionCard(
          icon: Icons.event_note,
          title: 'Sobre o Evento',
          color: AppTheme.primary,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.room.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.room.description ?? widget.room.type,
              style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Msgs expiram em ' + widget.room.messageTtlHours.toString() + 'h',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.people_outline,
          title: 'Comunicacao em Tempo Real',
          color: Colors.blue,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Usuarios conectados podem compartilhar informacoes em tempo real:',
              style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            _InfoItem(Icons.restaurant, 'Fila do lanche'),
            _InfoItem(Icons.wc, 'Fila do banheiro'),
            _InfoItem(Icons.child_care, 'Pessoas perdidas'),
            _InfoItem(Icons.confirmation_number, 'Bilheteria'),
            _InfoItem(Icons.exit_to_app, 'Saidas e acessos'),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.qr_code,
          title: 'Como Entrar',
          color: Colors.purple,
          child: Column(children: [
            const Text('Escaneie o QR Code ou acesse o link para baixar o app e entrar na sala do evento automaticamente.',
              style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
              child: Text(widget.room.qrData,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), textAlign: TextAlign.center),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMapTab() {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (_, __, ___) {
        final locMsgs = _msgs('LOCALIZACAO');
        return Column(children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.map, size: 64, color: AppTheme.primary),
                const SizedBox(height: 12),
                const Text('Mapa do Evento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Usuarios podem postar localizacoes de setores abaixo',
                  style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                if (locMsgs.isNotEmpty)
                  ...locMsgs.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.location_pin, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m.text.replaceFirst('[LOCALIZACAO] ', ''),
                        style: const TextStyle(fontSize: 12))),
                      Text(m.senderNick, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ]),
                  )),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _sectorCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: Palco principal - norte do parque',
                  labelText: 'Postar localizacao',
                  prefixIcon: Icon(Icons.location_pin),
                ),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () { _postMsg('LOCALIZACAO', _sectorCtrl.text); _sectorCtrl.clear(); },
                child: const Icon(Icons.send),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _buildScheduleTab() {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (_, __, ___) {
        final schedMsgs = _msgs('HORARIO');
        return Column(children: [
          Expanded(
            child: schedMsgs.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule, size: 48, color: AppTheme.textSecondary),
                  SizedBox(height: 12),
                  Text('Sem horarios publicados ainda.', style: TextStyle(color: AppTheme.textSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedMsgs.length,
                  itemBuilder: (_, i) {
                    final m = schedMsgs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.access_time, color: AppTheme.primary),
                        title: Text(m.text.replaceFirst('[HORARIO] ', '')),
                        subtitle: Text('por ' + m.senderNick,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                    );
                  }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _scheduleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex: 20:00 - Abertura dos portoes',
                  labelText: 'Publicar horario',
                  prefixIcon: Icon(Icons.schedule),
                ),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () { _postMsg('HORARIO', _scheduleCtrl.text); _scheduleCtrl.clear(); },
                child: const Icon(Icons.send),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _buildMsgTab(String tag, String hint, IconData icon, Color color, TextEditingController ctrl) {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (_, __, ___) {
        final tagMsgs = _msgs(tag);
        return Column(children: [
          Expanded(
            child: tagMsgs.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text('Sem ' + hint + ' ainda.', style: const TextStyle(color: AppTheme.textSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tagMsgs.length,
                  itemBuilder: (_, i) {
                    final m = tagMsgs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 20)),
                        title: Text(m.text.replaceFirst('[' + tag + '] ', '')),
                        subtitle: Text('por ' + m.senderNick + ' - ' + _timeAgo(m.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                    );
                  }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: hint,
                  labelText: 'Publicar informacao',
                  prefixIcon: Icon(icon, color: color),
                ),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () { _postMsg(tag, ctrl.text); ctrl.clear(); },
                child: const Icon(Icons.send),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _buildEmergencyTab() {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (_, __, ___) {
        final emergMsgs = _msgs('EMERGENCIA');
        final eCtrl = TextEditingController();
        return Column(children: [
          Container(
            color: Colors.red.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
            child: const Row(children: [
              Icon(Icons.emergency, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('EMERGENCIA: Use apenas para situacoes criticas. Todos serao notificados.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12))),
            ]),
          ),
          Expanded(
            child: emergMsgs.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                  SizedBox(height: 12),
                  Text('Nenhuma emergencia reportada', style: TextStyle(color: AppTheme.textSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: emergMsgs.length,
                  itemBuilder: (_, i) {
                    final m = emergMsgs[i];
                    return Card(
                      color: Colors.red.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.emergency, color: Colors.white, size: 18)),
                        title: Text(m.text.replaceFirst('[EMERGENCIA] ', ''), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('por ' + m.senderNick + ' - ' + _timeAgo(m.createdAt),
                          style: const TextStyle(fontSize: 11)),
                      ),
                    );
                  }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              Expanded(child: TextField(
                controller: eCtrl,
                decoration: const InputDecoration(
                  hintText: 'Descreva a emergencia...',
                  labelText: 'Reportar emergencia',
                  prefixIcon: Icon(Icons.emergency, color: Colors.red),
                ),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () { _postMsg('EMERGENCIA', eCtrl.text); eCtrl.clear(); },
                child: const Icon(Icons.send),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _buildSectorTab() {
    final tags = ['FILA_LANCHE', 'FILA_BANHEIRO', 'PERDIDOS', 'BILHETERIA', 'SETOR'];
    final labels = ['Fila Lanche', 'Fila Banheiro', 'Pessoas Perdidas', 'Bilheteria', 'Outros Setores'];
    final icons = [Icons.restaurant, Icons.wc, Icons.child_care, Icons.confirmation_number, Icons.grid_view];
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (_, __, ___) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tags.length,
          itemBuilder: (_, i) {
            final sectorMsgs = _msgs(tags[i]);
            final sCtrl = TextEditingController();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(icons[i], color: AppTheme.primary),
                title: Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(sectorMsgs.isEmpty ? 'Nenhuma info' : sectorMsgs.first.text.replaceFirst('[' + tags[i] + '] ', ''),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                children: [
                  ...sectorMsgs.map((m) => ListTile(
                    dense: true,
                    title: Text(m.text.replaceFirst('[' + tags[i] + '] ', ''), style: const TextStyle(fontSize: 13)),
                    subtitle: Text(m.senderNick + ' - ' + _timeAgo(m.createdAt), style: const TextStyle(fontSize: 10)),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Expanded(child: TextField(
                        controller: sCtrl,
                        decoration: InputDecoration(hintText: 'Atualizar ' + labels[i] + '...', isDense: true),
                      )),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () { _postMsg(tags[i], sCtrl.text); sCtrl.clear(); },
                        child: const Text('OK'),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return diff.inMinutes.toString() + 'min atrás';
    if (diff.inDays < 1) return diff.inHours.toString() + 'h atrás';
    return diff.inDays.toString() + 'd atrás';
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.color, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 20), const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
      ]),
      const Divider(height: 16),
      child,
    ]),
  );
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary), const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 13)),
    ]),
  );
}
