class RoomModel {
  final String id;
  final String name;
  final String type;
  final String qrData;
  final DateTime createdAt;
  final String? description;
  final String? creatorId;
  final int messageTtlHours;
  final bool isEvent;

  const RoomModel({
    required this.id, required this.name, required this.type,
    required this.qrData, required this.createdAt,
    this.description, this.creatorId,
    this.messageTtlHours = 24,
    this.isEvent = false,
  });

  static String buildQrData(String roomId) {
    return 'https://netcode.app/sala/' + roomId;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'type': type, 'qrData': qrData,
    'createdAt': createdAt.toIso8601String(), 'description': description,
    'creatorId': creatorId,
    'messageTtlHours': messageTtlHours,
    'isEvent': isEvent,
  };

  factory RoomModel.fromJson(Map<String, dynamic> j) => RoomModel(
    id: j['id'], name: j['name'], type: j['type'], qrData: j['qrData'],
    createdAt: DateTime.parse(j['createdAt']), description: j['description'],
    creatorId: j['creatorId'],
    messageTtlHours: (j['messageTtlHours'] as int?) ?? 24,
    isEvent: (j['isEvent'] as bool?) ?? false,
  );
}

enum RoomType {
  bairro('Bairro', '\u{1F3D8}'),
  condominio('Condominio', '\u{1F3E2}'),
  evento('Evento', '\u{1F3AA}'),
  show('Show', '\u{1F3B5}'),
  futebol('Futebol', '\u26BD'),
  feira('Feira', '\u{1F6D2}'),
  praia('Praia', '\u{1F3D6}'),
  trilha('Trilha', '\u{1F45E}'),
  carnaval('Carnaval', '\u{1F3AD}'),
  emergencia('Emergencia', '\u{1F6A8}'),
  protesto('Manifestacao', '\u270A'),
  turismo('Turismo', '\u{1F4F8}'),
  geral('Geral', '\u{1F4E1}');

  final String label;
  final String emoji;
  const RoomType(this.label, this.emoji);
}
