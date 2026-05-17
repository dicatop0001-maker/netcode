import 'package:hive/hive.dart';
part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel extends HiveObject {
    @HiveField(0) late String id;
    @HiveField(1) late String roomId;
    @HiveField(2) late String sellerId;
    @HiveField(3) late String sellerNick;
    @HiveField(4) late String title;
    @HiveField(5) late String description;
    @HiveField(6) late double price;
    @HiveField(7) List<String> imagePaths = [];
    @HiveField(8) late DateTime createdAt;
    @HiveField(9) late DateTime expiresAt;
    @HiveField(10) String category = 'Geral';
    @HiveField(11) bool available = true;
    @HiveField(12) String bairro = '';
    @HiveField(13) String cidade = '';

    ProductModel({
          required this.id, required this.roomId, required this.sellerId,
          required this.sellerNick, required this.title, required this.description,
          required this.price, required this.createdAt, required this.expiresAt,
          List<String>? imagePaths, this.category = 'Geral', this.available = true,
          this.bairro = '', this.cidade = '',
    }) : imagePaths = imagePaths ?? [];

    bool get isExpired => DateTime.now().isAfter(expiresAt);

    Map<String, dynamic> toJson() => {
          'id': id, 'roomId': roomId, 'sellerId': sellerId, 'sellerNick': sellerNick,
          'title': title, 'description': description, 'price': price,
          'imagePaths': imagePaths, 'createdAt': createdAt.toIso8601String(),
          'expiresAt': expiresAt.toIso8601String(), 'category': category,
          'available': available, 'bairro': bairro, 'cidade': cidade,
    };

    factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
          id: j['id'], roomId: j['roomId'], sellerId: j['sellerId'],
          sellerNick: j['sellerNick'], title: j['title'],
          description: j['description'], price: (j['price'] as num).toDouble(),
          createdAt: DateTime.parse(j['createdAt']),
          expiresAt: DateTime.parse(j['expiresAt']),
          imagePaths: List<String>.from(j['imagePaths'] ?? []),
          category: j['category'] ?? 'Geral', available: j['available'] ?? true,
          bairro: j['bairro'] ?? '', cidade: j['cidade'] ?? '',
        );
}
