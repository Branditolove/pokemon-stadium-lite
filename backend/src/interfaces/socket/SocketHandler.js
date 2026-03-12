const EVENTS = require('./events');
const { spawnInProcessBot } = require('../../bot_runner');
const JoinLobbyUseCase = require('../../application/usecases/JoinLobbyUseCase');
const AssignPokemonUseCase = require('../../application/usecases/AssignPokemonUseCase');
const ReadyUseCase = require('../../application/usecases/ReadyUseCase');
const AttackUseCase = require('../../application/usecases/AttackUseCase');
const GetPokemonListUseCase = require('../../application/usecases/GetPokemonListUseCase');
const BattleService = require('../../application/services/BattleService');

/**
 * SocketHandler - Maneja los eventos de Socket.IO
 */
class SocketHandler {
  constructor(io, lobbyRepository, playerRepository, battleRepository) {
    this.io = io;
    this.lobbyRepository = lobbyRepository;
    this.playerRepository = playerRepository;
    this.battleRepository = battleRepository;

    // Casos de uso
    this.joinLobbyUseCase = new JoinLobbyUseCase(lobbyRepository, playerRepository);
    this.assignPokemonUseCase = new AssignPokemonUseCase(playerRepository, lobbyRepository);
    this.readyUseCase = new ReadyUseCase(playerRepository, lobbyRepository);
    this.attackUseCase = new AttackUseCase(playerRepository, lobbyRepository, battleRepository);
    this.getPokemonListUseCase = new GetPokemonListUseCase();
    this.battleService = new BattleService(battleRepository);
  }

  /**
   * Helper: serializa un pokemon incluyendo moves
   */
  _serializePokemon(poke) {
    return {
      pokemonId: poke.pokemonId,
      name: poke.name,
      type: poke.type,
      hp: poke.hp,
      currentHp: poke.currentHp,
      attack: poke.attack,
      defense: poke.defense,
      speed: poke.speed,
      sprite: poke.sprite,
      defeated: poke.defeated,
      moves: poke.moves || []
    };
  }

  /**
   * Helper: serializa un jugador para emitir en lobby_status
   */
  _serializePlayer(p) {
    const activePokemon = p.getActivePokemon ? p.getActivePokemon() : null;
    return {
      id: p.id,
      nickname: p.nickname,
      ready: p.ready,
      team: p.team.map(poke => this._serializePokemon(poke)),
      isActive: p.isActive,
      currentPokemonName: activePokemon?.name ?? null
    };
  }

  /**
   * Registra los manejadores de eventos
   */
  registerHandlers(socket) {
    socket.on(EVENTS.JOIN_LOBBY, (payload) => this.handleJoinLobby(socket, payload));
    socket.on(EVENTS.ASSIGN_POKEMON, (payload) => this.handleAssignPokemon(socket, payload));
    socket.on(EVENTS.READY, () => this.handleReady(socket));
    socket.on(EVENTS.ATTACK, (payload) => this.handleAttack(socket, payload));
    socket.on(EVENTS.SWITCH_POKEMON, (payload) => this.handleSwitchPokemon(socket, payload));
    socket.on('get_pokemon_list', () => this.handleGetPokemonList(socket));
    socket.on('spawn_bot', (payload) => this.handleSpawnBot(socket, payload));
    socket.on('disconnect', () => this.handleDisconnect(socket));
  }

  /**
   * Maneja el evento get_pokemon_list
   */
  async handleGetPokemonList(socket) {
    try {
      const pokemonList = await this.getPokemonListUseCase.execute();
      socket.emit('pokemon_list', { pokemon: pokemonList });
    } catch (error) {
      console.error('Error in handleGetPokemonList:', error);
      socket.emit(EVENTS.ERROR, { message: error.message });
    }
  }

  /**
   * Maneja el evento join_lobby
   */
  async handleJoinLobby(socket, payload) {
    try {
      const { nickname } = payload;

      if (!nickname) {
        socket.emit(EVENTS.ERROR, { message: 'Nickname is required' });
        return;
      }

      const result = await this.joinLobbyUseCase.execute({
        nickname,
        socketId: socket.id
      });

      const { lobby, player } = result;

      socket.data.playerId = player.id;
      socket.data.lobbyId = lobby.id;

      socket.join(`lobby:${lobby.id}`);

      player.socketId = socket.id;
      await this.playerRepository.update(player);

      const updatedLobby = await this.lobbyRepository.findById(lobby.id);
      const playersData = await Promise.all(
        updatedLobby.players.map(p => this.playerRepository.findById(p.id))
      );
      updatedLobby.players = playersData;

      this.io.to(`lobby:${lobby.id}`).emit(EVENTS.LOBBY_STATUS, {
        status: updatedLobby.status,
        players: updatedLobby.players.map(p => this._serializePlayer(p))
      });
    } catch (error) {
      console.error('Error in handleJoinLobby:', error);
      socket.emit(EVENTS.ERROR, { message: error.message });
    }
  }

  /**
   * Maneja el evento assign_pokemon
   * payload: { pokemonIds: [id1, id2, id3] } (opcional)
   */
  async handleAssignPokemon(socket, payload) {
    try {
      const { playerId, lobbyId } = socket.data;

      if (!playerId || !lobbyId) {
        socket.emit(EVENTS.ERROR, { message: 'Player or lobby not found' });
        return;
      }

      const pokemonIds = payload && payload.pokemonIds ? payload.pokemonIds : null;

      const result = await this.assignPokemonUseCase.execute({
        playerId,
        lobbyId,
        pokemonIds
      });

      const lobby = await this.lobbyRepository.findById(lobbyId);
      const playersData = await Promise.all(
        lobby.players.map(p => this.playerRepository.findById(p.id))
      );
      lobby.players = playersData;

      this.io.to(`lobby:${lobbyId}`).emit(EVENTS.LOBBY_STATUS, {
        status: lobby.status,
        players: lobby.players.map(p => this._serializePlayer(p))
      });
    } catch (error) {
      console.error('Error in handleAssignPokemon:', error);
      socket.emit(EVENTS.ERROR, { message: error.message });
    }
  }

  /**
   * Maneja el evento ready
   */
  async handleReady(socket) {
    try {
      const { playerId, lobbyId } = socket.data;

      if (!playerId || !lobbyId) {
        socket.emit(EVENTS.ERROR, { message: 'Player or lobby not found' });
        return;
      }

      const result = await this.readyUseCase.execute({ playerId, lobbyId });
      const { canStartBattle } = result;

      const updatedLobby = await this.lobbyRepository.findById(lobbyId);
      const playersData = await Promise.all(
        updatedLobby.players.map(p => this.playerRepository.findById(p.id))
      );
      updatedLobby.players = playersData;

      this.io.to(`lobby:${lobbyId}`).emit(EVENTS.LOBBY_STATUS, {
        status: updatedLobby.status,
        players: updatedLobby.players.map(p => this._serializePlayer(p))
      });

      if (canStartBattle) {
        await this.startBattle(updatedLobby);
      }
    } catch (error) {
      console.error('Error in handleReady:', error);
      socket.emit(EVENTS.ERROR, { message: error.message });
    }
  }

  /**
   * Maneja el evento attack
   * payload: { moveName: string }
   */
  async handleAttack(socket, payload) {
    try {
      const { playerId, lobbyId } = socket.data;

      if (!playerId || !lobbyId) {
        socket.emit(EVENTS.ERROR, { message: 'Player or lobby not found' });
        return;
      }

      const moveName = payload && payload.moveName ? payload.moveName : null;

      const result = await this.attackUseCase.execute({
        playerId,
        lobbyId,
        moveName
      });

      const {
        damage,
        moveName: usedMove,
        defenderCurrentHp,
        pokemonDefeated,
        newPokemon,
        nextTurn,
        battleEnded,
        winner
      } = result;

      const lobby = await this.lobbyRepository.findById(lobbyId);
      const defender = lobby.getOpponent(playerId);

      this.io.to(`lobby:${lobbyId}`).emit(EVENTS.TURN_RESULT, {
        attacker: playerId,
        defender: defender.id,
        moveName: usedMove,
        damage,
        defenderCurrentHp,
        pokemonDefeated,
        newPokemon,
        nextTurn
      });

      if (battleEnded) {
        const finalLobby = await this.lobbyRepository.findById(lobbyId);
        const playersData = await Promise.all(
          finalLobby.players.map(p => this.playerRepository.findById(p.id))
        );
        finalLobby.players = playersData;

        const winnerPlayer = playersData.find(p => p.id === winner);
        const brandonMessage = winnerPlayer?.nickname === 'Brandon'
          ? '¡Jaja! Me contrataron específicamente para esto. 💼😎\n— Brandon'
          : null;

        this.io.to(`lobby:${lobbyId}`).emit(EVENTS.BATTLE_END, { winner, brandonMessage });

        this.io.to(`lobby:${lobbyId}`).emit(EVENTS.LOBBY_STATUS, {
          status: finalLobby.status,
          players: finalLobby.players.map(p => this._serializePlayer(p))
        });

        // Limpiar lobby y jugadores de la DB para que el próximo juego empiece fresco
        await this.lobbyRepository.delete(lobbyId);
        console.log(`🧹 Lobby ${lobbyId} eliminado tras fin de batalla.`);
      }
    } catch (error) {
      console.error('Error in handleAttack:', error);
      socket.emit(EVENTS.ERROR, { message: error.message });
    }
  }

  /**
   * Maneja el cambio de pokémon activo (elección del jugador)
   * payload: { pokemonName: string }
   */
  async handleSwitchPokemon(socket, payload) {
    try {
      const { playerId, lobbyId } = socket.data;
      const { pokemonName } = payload || {};

      if (!playerId || !pokemonName) return;

      const player = await this.playerRepository.findById(playerId);
      if (!player) return;

      // Verificar que el pokemon existe, no está derrotado y pertenece al jugador
      const targetPokemon = player.team.find(p => p.name === pokemonName && !p.defeated);
      if (!targetPokemon) return;

      player.setActivePokemon(pokemonName);
      await this.playerRepository.update(player);

      // Notificar al lobby del cambio
      if (lobbyId) {
        const lobby = await this.lobbyRepository.findById(lobbyId);
        if (lobby) {
          const playersData = await Promise.all(
            lobby.players.map(p => this.playerRepository.findById(p.id))
          );
          lobby.players = playersData;
          this.io.to(`lobby:${lobbyId}`).emit(EVENTS.LOBBY_STATUS, {
            status: lobby.status,
            players: lobby.players.map(p => this._serializePlayer(p))
          });
        }
      }
    } catch (error) {
      console.error('Error in handleSwitchPokemon:', error);
    }
  }

  /**
   * Spawna un bot según la dificultad solicitada
   * difficulty: 'easy' (Toby) | 'medium' (Gary) | 'brandon' (Brandon)
   */
  handleSpawnBot(socket, payload) {
    try {
      const { difficulty } = payload || {};
      const diffMap = { easy: 'Toby', medium: 'Gary', brandon: 'Brandon' };
      const nickname = diffMap[difficulty] || 'Gary';
      const validDifficulty = diffMap[difficulty] ? difficulty : 'medium';

      const PORT = process.env.PORT || 8080;
      const backendUrl = `http://127.0.0.1:${PORT}`;

      spawnInProcessBot({ url: backendUrl, nickname, difficulty: validDifficulty });

      console.log(`🤖 Bot spawneado in-process: ${nickname} [${validDifficulty}]`);
    } catch (error) {
      console.error('Error spawning bot:', error);
    }
  }

  /**
   * Maneja la desconexión de un cliente
   */
  async handleDisconnect(socket) {
    try {
      const { playerId, lobbyId } = socket.data;

      if (!playerId || !lobbyId) return;

      const player = await this.playerRepository.findById(playerId);
      if (player) {
        player.markAsInactive();
        await this.playerRepository.update(player);
      }

      const lobby = await this.lobbyRepository.findById(lobbyId);
      if (!lobby) {
        console.log(`Player ${playerId} disconnected`);
        return;
      }

      if (lobby.status === 'battling') {
        const opponent = lobby.getOpponent(playerId);
        if (opponent) {
          this.io.to(`lobby:${lobbyId}`).emit(EVENTS.BATTLE_END, { winner: opponent.id });
        }
        // Eliminar lobby y liberar el slot para la próxima partida
        await this.lobbyRepository.delete(lobbyId);
        console.log(`🧹 Lobby ${lobbyId} eliminado por desconexión en batalla.`);
      } else if (lobby.status === 'finished') {
        // Lobby ya terminado, solo limpiar si quedan referencias
        await this.lobbyRepository.delete(lobbyId);
        console.log(`🧹 Lobby ${lobbyId} eliminado (ya estaba terminado).`);
      } else if (lobby.status === 'waiting' || lobby.status === 'ready') {
        // Remover jugador desconectado del lobby
        lobby.players = lobby.players.filter(p => p.id !== playerId);
        if (lobby.players.length === 0) {
          await this.lobbyRepository.delete(lobbyId);
          console.log(`🧹 Lobby ${lobbyId} eliminado (sin jugadores).`);
        } else {
          lobby.status = 'waiting';
          await this.lobbyRepository.update(lobby);
        }
      }

      console.log(`Player ${playerId} disconnected`);
    } catch (error) {
      console.error('Error in handleDisconnect:', error);
    }
  }

  /**
   * Inicia la batalla
   */
  async startBattle(lobby) {
    try {
      lobby.startBattle();
      await this.lobbyRepository.update(lobby);

      await this.battleService.createBattle(lobby.id);

      const updatedLobby = await this.lobbyRepository.findById(lobby.id);
      const playersData = await Promise.all(
        updatedLobby.players.map(p => this.playerRepository.findById(p.id))
      );
      updatedLobby.players = playersData;

      this.io.to(`lobby:${lobby.id}`).emit(EVENTS.BATTLE_START, {
        currentTurn: updatedLobby.currentTurn,
        teams: updatedLobby.players.map(p => ({
          playerId: p.id,
          nickname: p.nickname,
          team: p.team.map(poke => this._serializePokemon(poke))
        }))
      });
    } catch (error) {
      console.error('Error starting battle:', error);
      this.io.to(`lobby:${lobby.id}`).emit(EVENTS.ERROR, { message: 'Failed to start battle' });
    }
  }
}

module.exports = SocketHandler;
