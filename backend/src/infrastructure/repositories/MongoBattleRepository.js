const IBattleRepository = require('../../domain/repositories/IBattleRepository');
const BattleModel = require('../database/models/BattleModel');
const Battle = require('../../domain/entities/Battle');

/**
 * MongoBattleRepository - Implementación de persistencia de batallas con MongoDB
 */
class MongoBattleRepository extends IBattleRepository {
  /**
   * Guarda una batalla en la base de datos
   * @param {Battle} battle
   * @returns {Promise<Battle>}
   */
  async save(battle) {
    try {
      const battleDoc = new BattleModel({
        lobbyId: battle.lobbyId,
        turns: battle.turns,
        winner: battle.winner,
        startedAt: battle.startedAt,
        endedAt: battle.endedAt
      });

      const saved = await battleDoc.save();
      battle.id = saved._id.toString();
      return battle;
    } catch (error) {
      console.error('Error saving battle:', error);
      throw error;
    }
  }

  /**
   * Busca una batalla por ID
   * @param {string} id
   * @returns {Promise<Battle|null>}
   */
  async findById(id) {
    try {
      const battleDoc = await BattleModel.findById(id);
      if (!battleDoc) return null;

      return this._mapToDomain(battleDoc);
    } catch (error) {
      console.error('Error finding battle by ID:', error);
      throw error;
    }
  }

  /**
   * Busca una batalla por ID de lobby
   * @param {string} lobbyId
   * @returns {Promise<Battle|null>}
   */
  async findByLobbyId(lobbyId) {
    try {
      const battleDoc = await BattleModel.findOne({ lobbyId });
      if (!battleDoc) return null;

      return this._mapToDomain(battleDoc);
    } catch (error) {
      console.error('Error finding battle by lobby ID:', error);
      throw error;
    }
  }

  /**
   * Actualiza una batalla
   * @param {Battle} battle
   * @returns {Promise<Battle>}
   */
  async update(battle) {
    try {
      const updated = await BattleModel.findByIdAndUpdate(
        battle.id,
        {
          lobbyId: battle.lobbyId,
          turns: battle.turns,
          winner: battle.winner,
          startedAt: battle.startedAt,
          endedAt: battle.endedAt
        },
        { new: true }
      );

      return this._mapToDomain(updated);
    } catch (error) {
      console.error('Error updating battle:', error);
      throw error;
    }
  }

  /**
   * Elimina una batalla
   * @param {string} id
   * @returns {Promise<void>}
   */
  async delete(id) {
    try {
      await BattleModel.findByIdAndDelete(id);
    } catch (error) {
      console.error('Error deleting battle:', error);
      throw error;
    }
  }

  /**
   * Mapea un documento de MongoDB a una entidad Battle del dominio
   * @private
   * @param {object} battleDoc
   * @returns {Battle}
   */
  _mapToDomain(battleDoc) {
    const battle = new Battle(
      battleDoc._id.toString(),
      battleDoc.lobbyId.toString()
    );
    battle.turns = battleDoc.turns || [];
    battle.winner = battleDoc.winner ? battleDoc.winner.toString() : null;
    battle.startedAt = battleDoc.startedAt;
    battle.endedAt = battleDoc.endedAt;
    return battle;
  }
}

module.exports = MongoBattleRepository;
