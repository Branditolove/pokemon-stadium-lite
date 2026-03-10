class MoveModel {
  final String name;
  final int power;
  final String type;
  final int pp;

  const MoveModel({
    required this.name,
    required this.power,
    required this.type,
    required this.pp,
  });

  factory MoveModel.fromJson(Map<String, dynamic> json) {
    return MoveModel(
      name: json['name'] ?? 'tackle',
      power: (json['power'] as num?)?.toInt() ?? 40,
      type: json['type'] ?? 'normal',
      pp: (json['pp'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'power': power,
      'type': type,
      'pp': pp,
    };
  }

  MoveModel copyWith({
    String? name,
    int? power,
    String? type,
    int? pp,
  }) {
    return MoveModel(
      name: name ?? this.name,
      power: power ?? this.power,
      type: type ?? this.type,
      pp: pp ?? this.pp,
    );
  }
}
