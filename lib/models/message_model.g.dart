// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'message_model.dart';

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override final int typeId = 0;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String, roomId: fields[1] as String,
      senderId: fields[2] as String, senderNick: fields[3] as String,
      text: fields[4] as String, createdAt: fields[5] as DateTime,
      expiresAt: fields[6] as DateTime, imagePath: fields[7] as String?,
      forwarded: fields[8] as bool, seenBy: (fields[9] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer..writeByte(10)
      ..writeByte(0)..write(obj.id)..writeByte(1)..write(obj.roomId)
      ..writeByte(2)..write(obj.senderId)..writeByte(3)..write(obj.senderNick)
      ..writeByte(4)..write(obj.text)..writeByte(5)..write(obj.createdAt)
      ..writeByte(6)..write(obj.expiresAt)..writeByte(7)..write(obj.imagePath)
      ..writeByte(8)..write(obj.forwarded)..writeByte(9)..write(obj.seenBy);
  }

  @override bool operator ==(Object other) =>
      identical(this, other) || other is MessageModelAdapter &&
          runtimeType == other.runtimeType && typeId == other.typeId;
  @override int get hashCode => typeId.hashCode;
}
