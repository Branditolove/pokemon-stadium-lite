import 'dart:io';
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
  bool _needsPokemonSwitch = false;
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
  bool get needsPokemonSwitch => _needsPokemonSwitch;
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

    _socketService.on('lobby_preview', (data) {
      _handleLobbyPreview(data);
    });

    // Reset session state on disconnect so stale player data is cleared
    _socketService.on('disconnect', (_) {
      if (_currentPlayer != null) {
        _currentPlayer = null;
        _lobby = LobbyModel();
        _needsTeamSelection = false;
        _needsPokemonSwitch = false;
        _availablePokemon = [];
        _pendingBotDifficulty = null;
        _selectedBotName = null;
        notifyListeners();
      }
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
        _needsPokemonSwitch = false;
        _battleLog.add('¡La batalla ha comenzado!');

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

        // Capture names BEFORE update for classic faint messages
        final attackerPokemonName = attackerPlayer?.activePokemon?.name;
        final defeatedPokemonName = defenderPlayer?.activePokemon?.name;

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
              // For the opponent, auto-update their active pokemon and log it
              // For the current player, they will choose via switch dialog
              if (defender != _currentPlayer?.id) {
                updatedCurrentPokemonName = newPokemon.name;
                _battleLog.add('¡${defenderPlayer.nickname} envió a ${_capitalize(newPokemon.name)}!');
              }
              // For the current player, we'll set currentPokemonName after they choose
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

        // Classic Pokémon battle log messages
        final attackerName = attackerPokemonName ?? attackerPlayer?.nickname ?? '???';
        if (moveName != null) {
          _battleLog.add('¡${_capitalize(attackerName)} usó ${_formatMoveName(moveName)}!');
        }
        if (damage > 0) {
          _battleLog.add('¡Causó $damage puntos de daño!');
        }

        if (pokemonDefeated && defeatedPokemonName != null) {
          _battleLog.add('¡${_capitalize(defeatedPokemonName)} se ha debilitado!');
        }

        _isMyTurn = nextTurn == _currentPlayer?.id;

        // Check if current player needs to choose next pokemon
        if (pokemonDefeated && _currentPlayer?.id == defender) {
          final alivePokemon = _currentPlayer?.team.where((p) => !p.defeated).toList() ?? [];
          if (alivePokemon.isNotEmpty) {
            _needsPokemonSwitch = true;
          }
        }

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
        _battleLog.add('¡La batalla ha terminado!');
        _needsPokemonSwitch = false;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling battle end: $e');
    }
  }

  void _handleLobbyPreview(dynamic data) {
    if (_currentPlayer != null) return; // Ya unido, ignorar preview
    try {
      if (data is Map<String, dynamic>) {
        final players = (data['players'] as List?)
                ?.map((p) => PlayerModel.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];
        _lobby = _lobby.copyWith(players: players);
        notifyListeners();
      }
    } catch (e) {
      print('Error handling lobby preview: $e');
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
      _needsPokemonSwitch = false;
      _availablePokemon = [];
      notifyListeners();

      // Ping HTTP para despertar el backend (Railway puede tardar en responder)
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 8);
        final req = await client.getUrl(Uri.parse(baseUrl));
        await req.close();
        client.close();
      } catch (_) {
        // El ping es solo de "wake up", si falla continuamos igual
      }

      _socketService.connect(baseUrl);

      // Esperar conexión cada 500ms (hasta 15s)
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_socketService.isConnected) break;
      }

      if (!_socketService.isConnected) {
        final socketError = _socketService.lastError;
        _errorMessage = socketError != null
            ? 'No se pudo conectar al servidor ($baseUrl). Error: $socketError'
            : 'No se pudo conectar al servidor ($baseUrl). Verifica que el backend esté corriendo y la IP sea correcta.';
      } else {
        _errorMessage = null;
        _socketService.emit('get_lobby_status', {});
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

  void spawnBot(String difficulty) {
    // Clear pending bot so _handleLobbyStatus auto-spawn doesn't fire a second time
    _pendingBotDifficulty = null;
    _needsTeamSelection = true;
    // Pedir la lista de pokemon antes de navegar a PokemonSelectionScreen
    _socketService.emit('get_pokemon_list', {});
    _socketService.emit('spawn_bot', {'difficulty': difficulty});
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

  /// Cambia el pokemon activo del jugador (cuando el anterior se debilita)
  void switchPokemon(String pokemonName) {
    _socketService.emit('switch_pokemon', {'pokemonName': pokemonName});

    // Actualizar estado local
    if (_currentPlayer != null) {
      _currentPlayer = _currentPlayer!.copyWith(currentPokemonName: pokemonName);
    }

    final updatedPlayers = _lobby.players.map((p) {
      if (p.id == _currentPlayer?.id) return p.copyWith(currentPokemonName: pokemonName);
      return p;
    }).toList();
    _lobby = _lobby.copyWith(players: updatedPlayers);

    final pokemon = _currentPlayer?.team.where((p) => p.name == pokemonName).firstOrNull;
    if (pokemon != null) {
      _battleLog.add('¡Vamos, ${_capitalize(pokemon.name)}!');
    }

    _needsPokemonSwitch = false;
    notifyListeners();
  }

  void clearBattleLog() {
    _battleLog.clear();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Resets player session without disconnecting the socket.
  /// Useful when the user wants to play again with a different name.
  void resetPlayerState() {
    _currentPlayer = null;
    _lobby = LobbyModel();
    _battleLog.clear();
    _isMyTurn = false;
    _needsTeamSelection = false;
    _needsPokemonSwitch = false;
    _availablePokemon = [];
    _pendingBotDifficulty = null;
    _selectedBotName = null;
    _brandonMessage = null;
    _errorMessage = null;
    // Refrescar preview del lobby para ver jugadores esperando
    if (_socketService.isConnected) {
      _socketService.emit('get_lobby_status', {});
    }
    notifyListeners();
  }

  void disconnect() {
    _socketService.disconnect();
    _lobby = LobbyModel();
    _currentPlayer = null;
    _battleLog.clear();
    _isMyTurn = false;
    _needsTeamSelection = false;
    _needsPokemonSwitch = false;
    _availablePokemon = [];
    _pendingBotDifficulty = null;
    _selectedBotName = null;
    _brandonMessage = null;
    notifyListeners();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatMoveName(String name) {
    return name.split('-').map(_capitalize).join(' ');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
