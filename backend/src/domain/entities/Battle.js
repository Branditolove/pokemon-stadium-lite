/**
 * Battle Entity - Representa el histórico de una batalla
 */
class Battle {
  constructor(id, lobbyId) {
    this.id = id;
    this.lobbyId = lobbyId;
    this.turns = []; // Array de turnos
    this.winner = null; // ID del ganador
    this.startedAt = new Date();
    this.endedAt = null;
  }

  /**
   * Registra un turno en la batalla
   * @param {object} turn - {attacker: id, defender: id, damage: number, timestamp: Date}
   */
  recordTurn(turn) {
    this.turns.push({
      attacker: turn.attacker,
      defender: turn.defender,
      damage: turn.damage,
      timestamp: new Date()
    });
  }

  /**
   * Finaliza la batalla con un ganador
   * @param {string} winnerId
   */
  setWinner(winnerId) {
    this.winner = winnerId;
    this.endedAt = new Date();
  }

  /**
   * Obtiene el historial de turnos
   * @returns {Array}
   */
  getTurns() {
    return this.turns;
  }

  /**
   * Obtiene la información serializable de la batalla
   * @returns {object}
   */
  getState() {
    return {
      id: this.id,
      lobbyId: this.lobbyId,
      turns: this.turns,
      winner: this.winner,
      startedAt: this.startedAt,
      endedAt: this.endedAt
    };
  }
}

module.exports = Battle;
