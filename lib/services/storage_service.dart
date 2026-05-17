import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/message_model.dart';
import '../models/product_model.dart';
import '../models/room_model.dart';

class StorageService {
    static Box get _s => Hive.box('settings');

    static String? getNickname() => _s.get('nickname') as String?;
    static Future<void> saveNickname(String n) => _s.put('nickname', n);

    static String getDeviceId() {
          String? id = _s.get('deviceId') as String?;
          if (id == null) { id = const Uuid().v4(); _s.put('deviceId', id); }
          return id;
    }

    static RoomModel? getRoom(String id) {
          final raw = _s.get('room_$id') as String?;
          if (raw == null) return null;
          try { return RoomModel.fromJson(jsonDecode(raw) as Map<String, dynamic>); }
          catch (_) { return null; }
    }

    static Future<void> saveRoom(RoomModel r) =>
          _s.put('room_${r.id}', jsonEncode(r.toJson()));

    static Future<void> deleteRoom(String id) => _s.delete('room_$id');

    static bool isRoomCreator(String roomId) {
          final room = getRoom(roomId);
          if (room == null) return false;
          return room.creatorId == getDeviceId();
    }

    static List<RoomModel> getAllRooms() {
          final rooms = <RoomModel>[];
          for (final k in _s.keys) {
                  if (k.toString().startsWith('room_')) {
                            final raw = _s.get(k) as String?;
                            if (raw != null) {
                                        try { rooms.add(RoomModel.fromJson(jsonDecode(raw) as Map<String, dynamic>)); }
                                        catch (_) {}
                            }
                  }
          }
          rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rooms;
    }

    static RoomModel? _currentRoom;
    static RoomModel? getCurrentRoom() => _currentRoom;
    static void setCurrentRoom(RoomModel? r) => _currentRoom = r;

    static void cleanExpiredMessages() {
          final box = Hive.box<MessageModel>('messages');
          for (final m in box.values.where((m) => m.isExpired).toList()) { m.delete(); }
    }

    static void cleanExpiredProducts() {
          final box = Hive.box<ProductModel>('products');
          for (final p in box.values.where((p) => p.isExpired).toList()) { p.delete(); }
    }
}
