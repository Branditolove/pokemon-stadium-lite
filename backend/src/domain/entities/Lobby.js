/**
 * Lobby Entity - Representa el lobby global de batalla
 */
class Lobby {
  constructor(id) {
    this.id = id;
    this.status = 'waiting'; // waiting | ready | battling | finished
    this.players = []; // Array de Player
    this.currentTurn = null; // ObjectId/ID del jugador cuyo turno es
    this.winner = null; // ObjectId/ID del ganador
    this.processingTurn = false; // Flag para evitar race conditions
    this.createdAt = new Date();
  }

  /**
   * Añade un jugador al lobby
   * @param {Player} player
   * @throws {Error} si el lobby está lleno
   */
  addPlayer(player) {
    if (this.players.length >= 2) {
      throw new Error('Lobby is full');
    }
    this.players.push(player);
  }

  /**
   * Obtiene un jugador por ID
   * @param {string} playerId
   * @returns {Player|null}
   */
  getPlayerById(playerId) {
    return this.players.find(p => p.id === playerId) || null;
  }

  /**
   * Obtiene un jugador por socket ID
   * @param {string} socketId
   * @returns {Player|null}
   */
  getPlayerBySocketId(socketId) {
    return this.players.find(p => p.socketId === socketId) || null;
  }

  /**
   * Obtiene todos los jugadores activos
   * @returns {Array}
   */
  getActivePlayers() {
    return this.players.filter(p => p.isActive);
  }

  /**
   * Verifica si ambos jugadores están listos
   * @returns {boolean}
   */
  bothPlayersReady() {
    return this.players.length === 2 && this.players.every(p => p.ready);
  }

  /**
   * Verifica si el lobby está lleno
   * @returns {boolean}
   */
  isFull() {
    return this.players.length >= 2;
  }

  /**
   * Inicia la batalla
   * @throws {Error} si no hay 2 jugadores listos
   */
  startBattle() {
    if (!this.bothPlayersReady()) {
      throw new Error('Both players must be ready to start battle');
    }
    if (this.players.length !== 2) {
      throw new Error('Exactly 2 players required to start battle');
    }

    // Determinar quién comienza basándose en el Speed del pokémon activo
    const player1ActivePokemon = this.players[0].getActivePokemon();
    const player2ActivePokemon = this.players[1].getActivePokemon();

    if (!player1ActivePokemon || !player2ActivePokemon) {
      throw new Error('Both players must have active pokémon');
    }

    if (player1ActivePokemon.speed >= player2ActivePokemon.speed) {
      this.currentTurn = this.players[0].id;
    } else {
      this.currentTurn = this.players[1].id;
    }

    this.status = 'battling';
  }

  /**
   * Cambia el turno al siguiente jugador
   */
  switchTurn() {
    const currentPlayerIndex = this.players.findIndex(p => p.id === this.currentTurn);
    const nextPlayerIndex = currentPlayerIndex === 0 ? 1 : 0;
    this.currentTurn = this.players[nextPlayerIndex].id;
  }

  /**
   * Obtiene el jugador cuyo turno es
   * @returns {Player|null}
   */
  getCurrentPlayer() {
    return this.getPlayerById(this.currentTurn);
  }

  /**
   * Obtiene el jugador oponente
   * @param {string} playerId
   * @returns {Player|null}
   */
  getOpponent(playerId) {
    return this.players.find(p => p.id !== playerId) || null;
  }

  /**
   * Termina la batalla con un ganador
   * @param {string} winnerId - ID del jugador ganador
   */
  endBattle(winnerId) {
    this.status = 'finished';
    this.winner = winnerId;
  }

  /**
   * Cambia el estado del lobby a "ready"
   */
  markAsReady() {
    this.status = 'ready';
  }

  /**
   * Obtiene el estado serializable del lobby
   * @returns {object}
   */
  getState() {
    return {
      id: this.id,
      status: this.status,
      players: this.players.map(p => ({
        id: p.id,
        nickname: p.nickname,
        ready: p.ready,
        team: p.team.map(poke => poke.getCurrentState()),
        isActive: p.isActive
      })),
      currentTurn: this.currentTurn,
      winner: this.winner,
      createdAt: this.createdAt
    };
  }
}

module.exports = Lobby;
