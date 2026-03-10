import 'player_model.dart';

class LobbyModel {
  String status; // waiting, ready, battling, finished
  List<PlayerModel> players;
  String? currentTurn; // ID del jugador con turno
  String? winner; // ID del ganador

  LobbyModel({
    this.status = 'waiting',
    this.players = const [],
    this.currentTurn,
    this.winner,
  });

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    return LobbyModel(
      status: json['status'] ?? 'waiting',
      players: (json['players'] as List?)
              ?.map((p) => PlayerModel.fromJson(p))
              .toList() ??
          [],
      currentTurn: json['currentTurn'],
      winner: json['winner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'players': players.map((p) => p.toJson()).toList(),
      'currentTurn': currentTurn,
      'winner': winner,
    };
  }

  LobbyModel copyWith({
    String? status,
    List<PlayerModel>? players,
    String? currentTurn,
    String? winner,
  }) {
    return LobbyModel(
      status: status ?? this.status,
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      winner: winner ?? this.winner,
    );
  }

  bool get isReady => status == 'ready';
  bool get isBattling => status == 'battling';
  bool get isFinished => status == 'finished';
  bool get isWaiting => status == 'waiting';

  bool get allPlayersReady => players.every((p) => p.ready);
  int get playerCount => players.length;
}
