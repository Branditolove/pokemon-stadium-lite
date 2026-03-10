import 'move_model.dart';

class PokemonModel {
  final int id;
  final String name;
  final List<String> type;
  final int hp;
  int currentHp;
  final int attack;
  final int defense;
  final int speed;
  final String sprite;
  bool defeated;
  final List<MoveModel> moves;

  PokemonModel({
    required this.id,
    required this.name,
    required this.type,
    required this.hp,
    required this.currentHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.sprite,
    this.defeated = false,
    this.moves = const [],
  });

  factory PokemonModel.fromJson(Map<String, dynamic> json) {
    return PokemonModel(
      id: json['pokemonId'] ?? json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      type: List<String>.from(json['type'] ?? []),
      hp: json['hp'] ?? 0,
      currentHp: json['currentHp'] ?? json['hp'] ?? 0,
      attack: json['attack'] ?? 0,
      defense: json['defense'] ?? 0,
      speed: json['speed'] ?? 0,
      sprite: json['sprite'] ?? '',
      defeated: json['defeated'] ?? false,
      moves: (json['moves'] as List?)
              ?.map((m) => MoveModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'hp': hp,
      'currentHp': currentHp,
      'attack': attack,
      'defense': defense,
      'speed': speed,
      'sprite': sprite,
      'defeated': defeated,
      'moves': moves.map((m) => m.toJson()).toList(),
    };
  }

  PokemonModel copyWith({
    int? id,
    String? name,
    List<String>? type,
    int? hp,
    int? currentHp,
    int? attack,
    int? defense,
    int? speed,
    String? sprite,
    bool? defeated,
    List<MoveModel>? moves,
  }) {
    return PokemonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      hp: hp ?? this.hp,
      currentHp: currentHp ?? this.currentHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      sprite: sprite ?? this.sprite,
      defeated: defeated ?? this.defeated,
      moves: moves ?? this.moves,
    );
  }

  double get hpPercentage => hp > 0 ? currentHp / hp : 0;
}
