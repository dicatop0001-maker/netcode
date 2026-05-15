import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';
import 'storage_service.dart';

/// Stage 5: Nearby Connections API (discovery, advertising, connection)
/// Stage 6: Mesh retransmission - A -> B -> C -> D
class NearbyService {
  static const _serviceId = 'com.netcode.mesh';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  final Nearby _nearby = Nearby();
  final Map<String, String> _connected = {};
  final Set<String> _forwarded = {};

  void Function(MessageModel)? onMessageReceived;

  final _peerCount = StreamController<int>.broadcast();
  final _status = StreamController<String>.broadcast();

  Stream<int> get peerCountStream => _peerCount.stream;
  Stream<String> get statusStream => _status.stream;

  Future<void> init() async { await _requestPermissions(); }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth, Permission.bluetoothScan,
      Permission.bluetoothConnect, Permission.bluetoothAdvertise,
      Permission.locationWhenInUse, Permission.nearbyWifiDevices,
    ].request();
  }

  Future<void> joinRoom(dynamic room) async {
    _status.add('Iniciando rede local...');
    await _startAdvertising();
    await _startDiscovery();
  }

  Future<void> _startAdvertising() async {
    try {
      await _nearby.startAdvertising(
        StorageService.getNickname() ?? 'User', _strategy,
        onConnectionInitiated: _onConnInit,
        onConnectionResult: _onConnResult,
        onDisconnected: _onDisconn,
        serviceId: _serviceId);
      _status.add('Anunciando na rede...');
    } catch (e) { _status.add('Erro ao anunciar'); }
  }

  Future<void> _startDiscovery() async {
    try {
      await _nearby.startDiscovery(
        StorageService.getDeviceId(), _strategy,
        onEndpointFound: _onFound,
        onEndpointLost: _onLost,
        serviceId: _serviceId);
      _status.add('Buscando dispositivos...');
    } catch (e) { _status.add('Erro na busca'); }
  }

  void _onFound(String epId, String epName, String svcId) {
    _status.add('Encontrado: $epName');
    _nearby.requestConnection(
      StorageService.getNickname() ?? 'User', epId,
      onConnectionInitiated: _onConnInit,
      onConnectionResult: _onConnResult,
      onDisconnected: _onDisconn);
  }

  void _onLost(String? epId) {
    if (epId != null) {
      _connected.remove(epId);
      _peerCount.add(_connected.length);
    }
  }

  void _onConnInit(String epId, ConnectionInfo info) {
    _nearby.acceptConnection(epId,
        onPayLoadRecieved: _onPayload,
        onPayloadTransferUpdate: (_, __) {});
  }

  void _onConnResult(String epId, Status status) {
    if (status == Status.CONNECTED) {
      _connected[epId] = epId;
      _peerCount.add(_connected.length);
      _status.add('Mesh ativo - ${_connected.length} dispositivo(s)');
    } else {
      _connected.remove(epId);
      _peerCount.add(_connected.length);
    }
  }

  void _onDisconn(String epId) {
    _connected.remove(epId);
    _peerCount.add(_connected.length);
    _status.add('${_connected.length} na rede');
  }

  /// Stage 6: Receive payload + RELAY to all other peers (mesh A->B->C->D)
  void _onPayload(String epId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
    try {
      final json = jsonDecode(utf8.decode(payload.bytes!)) as Map<String, dynamic>;
      if (json['type'] != 'message') return;
      final msg = MessageModel.fromJson(json['data'] as Map<String, dynamic>);
      if (msg.isExpired || _forwarded.contains(msg.id)) return;

      // 1. Deliver locally
      onMessageReceived?.call(msg);

      // 2. RELAY - mesh retransmission (skip sender)
      _relay(msg, exclude: epId);
    } catch (_) {}
  }

  /// Send to all peers
  void sendMessage(MessageModel msg) {
    _forwarded.add(msg.id);
    final bytes = _encode(msg);
    for (final ep in _connected.keys) {
      try { _nearby.sendBytesPayload(ep, bytes); } catch (_) {}
    }
  }

  /// MESH CORE: relay to all except sender - A->B->C->D
  void _relay(MessageModel msg, {String? exclude}) {
    _forwarded.add(msg.id);
    final bytes = _encode(msg);
    for (final ep in _connected.keys) {
      if (ep == exclude) continue;
      try { _nearby.sendBytesPayload(ep, bytes); } catch (_) {}
    }
  }

  Uint8List _encode(MessageModel msg) => Uint8List.fromList(
    utf8.encode(jsonEncode({'type': 'message', 'data': msg.toJson()})));

  Future<void> stop() async {
    try {
      await _nearby.stopAdvertising();
      await _nearby.stopDiscovery();
      await _nearby.stopAllEndpoints();
    } catch (_) {}
    _connected.clear();
    if (!_peerCount.isClosed) _peerCount.close();
    if (!_status.isClosed) _status.close();
  }
}
