import 'package:hive/hive.dart';
part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String roomId;
  @HiveField(2) late String senderId;
  @HiveField(3) late String senderNick;
  @HiveField(4) late String text;
  @HiveField(5) late DateTime createdAt;
  @HiveField(6) late DateTime expiresAt;
  @HiveField(7) String? imagePath;
  @HiveField(8) bool forwarded = false;
  @HiveField(9) List<String> seenBy = [];

  MessageModel({
    required this.id, required this.roomId, required this.senderId,
    required this.senderNick, required this.text, required this.createdAt,
    required this.expiresAt, this.imagePath, this.forwarded = false,
    List<String>? seenBy,
  }) : seenBy = seenBy ?? [];

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'id': id, 'roomId': roomId, 'senderId': senderId,
    'senderNick': senderNick, 'text': text,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'imagePath': imagePath, 'forwarded': forwarded, 'seenBy': seenBy,
  };

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id: j['id'], roomId: j['roomId'], senderId: j['senderId'],
    senderNick: j['senderNick'], text: j['text'],
    createdAt: DateTime.parse(j['createdAt']),
    expiresAt: DateTime.parse(j['expiresAt']),
    imagePath: j['imagePath'], forwarded: j['forwarded'] ?? false,
    seenBy: List<String>.from(j['seenBy'] ?? []),
  );
}
