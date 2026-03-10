import 'package:flutter/material.dart';
import '../../core/services/socket_service.dart';
import '../../data/models/lobby_model.dart';
import '../../data/models/player_model.dart';
import '../../data/models/pokemon_model.dart';

class GameProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  LobbyModel _lobby = LobbyModel();
  PlayerModel? _currentPlayer;
  List<String> _battleLog = [];
  bool _isMyTurn = false;
  String? _errorMessage;
  bool _isConnecting = false;
  bool _needsTeamSelection = false;
  List<dynamic> _availablePokemon = [];
  String? _pendingBotDifficulty;
  String? _selectedBotName;
  String? _brandonMessage;

  // Getters
  LobbyModel get lobby => _lobby;
  PlayerModel? get currentPlayer => _currentPlayer;
  List<String> get battleLog => _battleLog;
  bool get isMyTurn => _isMyTurn;
  String? get errorMessage => _errorMessage;
  bool get isConnecting => _isConnecting;
  bool get isSocketConnected => _socketService.isConnected;
  bool get needsTeamSelection => _needsTeamSelection;
  List<dynamic> get availablePokemon => _availablePokemon;
  String? get selectedBotName => _selectedBotName;
  String? get brandonMessage => _brandonMessage;

  GameProvider() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.on('lobby_status', (data) {
      _handleLobbyStatus(data);
    });

    _socketService.on('battle_start', (data) {
      _handleBattleStart(data);
    });

    _socketService.on('turn_result', (data) {
      _handleTurnResult(data);
    });

    _socketService.on('battle_end', (data) {
      _handleBattleEnd(data);
    });

    _socketService.on('pokemon_list', (data) {
      _handlePokemonList(data);
    });

    _socketService.on('error', (data) {
      _handleError(data);
    });
  }

  void _handleLobbyStatus(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _lobby = _lobby.copyWith(
          status: data['status'] ?? _lobby.status,
          players: (data['players'] as List?)
                  ?.map((p) => PlayerModel.fromJson(p))
                  .toList() ??
              _lobby.players,
        );

        if (_currentPlayer != null && _currentPlayer!.id != null) {
          final updatedPlayer = _lobby.players
              .where((p) => p.id == _currentPlayer!.id)
              .firstOrNull;
          if (updatedPlayer != null) {
            _currentPlayer = updatedPlayer.copyWith(nickname: _currentPlayer!.nickname);
          }
        } else if (_currentPlayer != null) {
          final updatedPlayer = _lobby.players
              .where((p) => p.nickname == _currentPlayer!.nickname)
              .firstOrNull;
          if (updatedPlayer != null) {
            _currentPlayer = updatedPlayer.copyWith(nickname: _currentPlayer!.nickname);
            // First time getting ID: request pokemon list and spawn bot
            if (!_needsTeamSelection && _currentPlayer!.team.isEmpty) {
              _needsTeamSelection = true;
              _socketService.emit('get_pokemon_list', {});
              if (_pendingBotDifficulty != null) {
                _socketService.emit('spawn_bot', {'difficulty': _pendingBotDifficulty});
                _pendingBotDifficulty = null;
              }
            }
          }
        }

        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling lobby status: $e');
    }
  }

  void _handlePokemonList(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _availablePokemon = (data['pokemon'] as List?) ?? [];
        notifyListeners();
      }
    } catch (e) {
      print('Error handling pokemon list: $e');
    }
  }

  void _handleBattleStart(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _battleLog.clear();
        _battleLog.add('¡Batalla iniciada!');

        _isMyTurn = data['currentTurn'] == _currentPlayer?.id;

        _lobby = _lobby.copyWith(status: 'battling');

        if (data['teams'] is List) {
          final teams = data['teams'] as List;
          final updatedPlayers = _lobby.players.map((player) {
            final teamData = teams
                .cast<Map<String, dynamic>>()
                .where((t) => t['playerId'] == player.id)
                .firstOrNull;
            if (teamData != null) {
              final pokemonList = teamData['team'] as List?;
              if (pokemonList != null) {
                final newTeam = pokemonList
                    .map((p) => PokemonModel.fromJson(p as Map<String, dynamic>))
                    .toList();
                return player.copyWith(
                  team: newTeam,
                  currentPokemonName: newTeam.isNotEmpty ? newTeam[0].name : player.currentPokemonName,
                );
              }
            }
            return player;
          }).toList();

          _lobby = _lobby.copyWith(players: updatedPlayers);

          if (_currentPlayer != null) {
            final updated = updatedPlayers
                .where((p) => p.id == _currentPlayer!.id)
                .firstOrNull;
            if (updated != null) _currentPlayer = updated;
          }
        }

        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling battle start: $e');
    }
  }

  void _handleTurnResult(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final attacker = data['attacker'] as String?;
        final defender = data['defender'] as String?;
        final damage = data['damage'] as int? ?? 0;
        final moveName = data['moveName'] as String?;
        final defenderCurrentHp = data['defenderCurrentHp'] as int?;
        final pokemonDefeated = data['pokemonDefeated'] as bool? ?? false;
        final newPokemonData = data['newPokemon'];
        final nextTurn = data['nextTurn'] as String?;

        final attackerPlayer = _lobby.players
            .where((p) => p.id == attacker)
            .firstOrNull;
        var defenderPlayer = _lobby.players
            .where((p) => p.id == defender)
            .firstOrNull;

        if (defenderPlayer != null && defenderCurrentHp != null) {
          final activePokemon = defenderPlayer.activePokemon;
          List<PokemonModel> updatedTeam = defenderPlayer.team;
          String? updatedCurrentPokemonName = defenderPlayer.currentPokemonName;

          if (activePokemon != null) {
            updatedTeam = defenderPlayer.team.map((p) {
              if (p.name == activePokemon.name) {
                return p.copyWith(
                  currentHp: defenderCurrentHp,
                  defeated: pokemonDefeated ? true : p.defeated,
                );
              }
              return p;
            }).toList();
          }

          if (newPokemonData != null) {
            PokemonModel? newPokemon;
            if (newPokemonData is Map<String, dynamic>) {
              newPokemon = PokemonModel.fromJson(newPokemonData);
            } else if (newPokemonData is String) {
              newPokemon = defenderPlayer.team
                  .where((p) => p.name == newPokemonData)
                  .firstOrNull;
            }
            if (newPokemon != null) {
              updatedCurrentPokemonName = newPokemon.name;
              _battleLog.add('${defenderPlayer.nickname} envió a ${newPokemon.name}');
            }
          }

          final updatedDefender = defenderPlayer.copyWith(
            team: updatedTeam,
            currentPokemonName: updatedCurrentPokemonName,
          );

          final updatedPlayers = _lobby.players.map((p) {
            if (p.id == defender) return updatedDefender;
            return p;
          }).toList();

          _lobby = _lobby.copyWith(players: updatedPlayers);

          if (_currentPlayer?.id == defender) {
            _currentPlayer = updatedDefender;
          }

          defenderPlayer = updatedDefender;
        }

        if (attackerPlayer != null && defenderPlayer != null) {
          final moveStr = moveName != null ? ' usó $moveName y' : '';
          if (pokemonDefeated) {
            _battleLog.add('${attackerPlayer.nickname}$moveStr causó $damage de daño');
            _battleLog.add('El Pokémon de ${defenderPlayer.nickname} fue derrotado!');
          } else {
            _battleLog.add('${attackerPlayer.nickname}$moveStr causó $damage de daño');
          }
        }

        _isMyTurn = nextTurn == _currentPlayer?.id;

        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling turn result: $e');
    }
  }

  void _handleBattleEnd(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final winner = data['winner'] as String?;
        _brandonMessage = data['brandonMessage'] as String?;
        _lobby = _lobby.copyWith(
          status: 'finished',
          winner: winner,
        );
        _battleLog.add('¡Batalla finalizada!');
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling battle end: $e');
    }
  }

  void _handleError(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        _errorMessage = data['message'] as String? ?? 'Error desconocido';
      } else if (data is String) {
        _errorMessage = data;
      }
      notifyListeners();
    } catch (e) {
      print('Error handling error: $e');
    }
  }

  Future<void> connectToBackend(String baseUrl) async {
    try {
      _isConnecting = true;
      _currentPlayer = null;
      _lobby = LobbyModel();
      _battleLog.clear();
      _isMyTurn = false;
      _errorMessage = null;
      _needsTeamSelection = false;
      _availablePokemon = [];
      notifyListeners();

      _socketService.connect(baseUrl);

      await Future.delayed(const Duration(milliseconds: 3000));

      if (!_socketService.isConnected) {
        final socketError = _socketService.lastError;
        _errorMessage = socketError != null
            ? 'No se pudo conectar al servidor ($baseUrl). Error: $socketError'
            : 'No se pudo conectar al servidor ($baseUrl). Verifica que el backend esté corriendo y la IP sea correcta.';
      } else {
        _errorMessage = null;
      }

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      _isConnecting = false;
      notifyListeners();
    }
  }

  void setSelectedBot(String difficulty, String botName) {
    _pendingBotDifficulty = difficulty;
    _selectedBotName = botName;
    notifyListeners();
  }

  void joinLobby(String nickname) {
    _currentPlayer = PlayerModel(nickname: nickname);
    _socketService.emit('join_lobby', {'nickname': nickname});
    notifyListeners();
  }

  void selectTeam(List<int> pokemonIds) {
    _needsTeamSelection = false;
    _socketService.emit('assign_pokemon', {'pokemonIds': pokemonIds});
    notifyListeners();
  }

  void ready() {
    if (_currentPlayer != null) {
      _currentPlayer = _currentPlayer!.copyWith(ready: true);
    }
    _socketService.emit('ready');
    notifyListeners();
  }

  void attack(String moveName) {
    if (_isMyTurn) {
      _socketService.emit('attack', {'moveName': moveName});
    }
  }

  void clearBattleLog() {
    _battleLog.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void disconnect() {
    _socketService.disconnect();
    _lobby = LobbyModel();
    _currentPlayer = null;
    _battleLog.clear();
    _isMyTurn = false;
    _needsTeamSelection = false;
    _availablePokemon = [];
    _pendingBotDifficulty = null;
    _selectedBotName = null;
    _brandonMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
