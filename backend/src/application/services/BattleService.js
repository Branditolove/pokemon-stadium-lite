const Battle = require('../../domain/entities/Battle');

/**
 * BattleService - Servicio de aplicación para gestionar las batallas
 */
class BattleService {
  constructor(battleRepository) {
    this.battleRepository = battleRepository;
  }

  /**
   * Crea una nueva batalla
   * @param {string} lobbyId
   * @returns {Promise<Battle>}
   */
  async createBattle(lobbyId) {
    try {
      const battle = new Battle(null, lobbyId);
      return await this.battleRepository.save(battle);
    } catch (error) {
      console.error('Error creating battle:', error);
      throw error;
    }
  }

  /**
   * Obtiene una batalla existente
   * @param {string} battleId
   * @returns {Promise<Battle|null>}
   */
  async getBattle(battleId) {
    try {
      return await this.battleRepository.findById(battleId);
    } catch (error) {
      console.error('Error getting battle:', error);
      throw error;
    }
  }

  /**
   * Obtiene una batalla por lobby ID
   * @param {string} lobbyId
   * @returns {Promise<Battle|null>}
   */
  async getBattleByLobbyId(lobbyId) {
    try {
      return await this.battleRepository.findByLobbyId(lobbyId);
    } catch (error) {
      console.error('Error getting battle by lobby ID:', error);
      throw error;
    }
  }

  /**
   * Finaliza una batalla
   * @param {string} battleId
   * @param {string} winnerId
   * @returns {Promise<Battle>}
   */
  async endBattle(battleId, winnerId) {
    try {
      const battle = await this.battleRepository.findById(battleId);
      if (!battle) {
        throw new Error('Battle not found');
      }

      battle.setWinner(winnerId);
      return await this.battleRepository.update(battle);
    } catch (error) {
      console.error('Error ending battle:', error);
      throw error;
    }
  }
}

module.exports = BattleService;
