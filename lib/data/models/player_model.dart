import 'pokemon_model.dart';

class PlayerModel {
  final String? id;
  final String nickname;
  bool ready;
  List<PokemonModel> team;
  String? currentPokemonName;

  PlayerModel({
    this.id,
    required this.nickname,
    this.ready = false,
    this.team = const [],
    this.currentPokemonName,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'],
      nickname: json['nickname'] ?? 'Unknown',
      ready: json['ready'] ?? false,
      team: (json['team'] as List?)
              ?.map((p) => PokemonModel.fromJson(p))
              .toList() ??
          [],
      currentPokemonName: json['currentPokemonName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'ready': ready,
      'team': team.map((p) => p.toJson()).toList(),
      'currentPokemonName': currentPokemonName,
    };
  }

  PlayerModel copyWith({
    String? id,
    String? nickname,
    bool? ready,
    List<PokemonModel>? team,
    String? currentPokemonName,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      ready: ready ?? this.ready,
      team: team ?? this.team,
      currentPokemonName: currentPokemonName ?? this.currentPokemonName,
    );
  }

  int get activePokemonIndex {
    if (currentPokemonName == null || currentPokemonName!.isEmpty) {
      return 0;
    }
    return team.indexWhere((p) => p.name == currentPokemonName);
  }

  PokemonModel? get activePokemon {
    final index = activePokemonIndex;
    return index >= 0 && index < team.length ? team[index] : null;
  }

  bool get hasAlivePokemons => team.any((p) => !p.defeated);
}
