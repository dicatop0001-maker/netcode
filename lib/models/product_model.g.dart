// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'product_model.dart';

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override final int typeId = 1;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String, roomId: fields[1] as String,
      sellerId: fields[2] as String, sellerNick: fields[3] as String,
      title: fields[4] as String, description: fields[5] as String,
      price: fields[6] as double, createdAt: fields[7] as DateTime,
      expiresAt: fields[8] as DateTime,
      imagePaths: (fields[9] as List).cast<String>(),
      category: fields[10] as String, available: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer..writeByte(12)
      ..writeByte(0)..write(obj.id)..writeByte(1)..write(obj.roomId)
      ..writeByte(2)..write(obj.sellerId)..writeByte(3)..write(obj.sellerNick)
      ..writeByte(4)..write(obj.title)..writeByte(5)..write(obj.description)
      ..writeByte(6)..write(obj.price)..writeByte(7)..write(obj.createdAt)
      ..writeByte(8)..write(obj.expiresAt)..writeByte(9)..write(obj.imagePaths)
      ..writeByte(10)..write(obj.category)..writeByte(11)..write(obj.available);
  }

  @override bool operator ==(Object other) =>
      identical(this, other) || other is ProductModelAdapter &&
          runtimeType == other.runtimeType && typeId == other.typeId;
  @override int get hashCode => typeId.hashCode;
}
