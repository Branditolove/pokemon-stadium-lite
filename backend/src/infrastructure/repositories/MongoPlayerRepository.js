const IPlayerRepository = require('../../domain/repositories/IPlayerRepository');
const PlayerModel = require('../database/models/PlayerModel');
const Player = require('../../domain/entities/Player');
const PokemonState = require('../../domain/entities/PokemonState');

/**
 * MongoPlayerRepository - Implementación de persistencia de jugadores con MongoDB
 */
class MongoPlayerRepository extends IPlayerRepository {
  /**
   * Guarda un jugador en la base de datos
   * @param {Player} player
   * @returns {Promise<Player>}
   */
  async save(player) {
    try {
      const playerDoc = new PlayerModel({
        nickname: player.nickname,
        socketId: player.socketId,
        lobbyId: player.lobbyId,
        team: player.team.map(p => p.getCurrentState()),
        ready: player.ready,
        isActive: player.isActive
      });

      const saved = await playerDoc.save();
      player.id = saved._id.toString();
      return player;
    } catch (error) {
      console.error('Error saving player:', error);
      throw error;
    }
  }

  /**
   * Busca un jugador por ID
   * @param {string} id
   * @returns {Promise<Player|null>}
   */
  async findById(id) {
    try {
      const playerDoc = await PlayerModel.findById(id);
      if (!playerDoc) return null;

      return this._mapToDomain(playerDoc);
    } catch (error) {
      console.error('Error finding player by ID:', error);
      throw error;
    }
  }

  /**
   * Busca un jugador por nickname
   * @param {string} nickname
   * @returns {Promise<Player|null>}
   */
  async findByNickname(nickname) {
    try {
      const playerDoc = await PlayerModel.findOne({ nickname });
      if (!playerDoc) return null;

      return this._mapToDomain(playerDoc);
    } catch (error) {
      console.error('Error finding player by nickname:', error);
      throw error;
    }
  }

  /**
   * Actualiza un jugador
   * @param {Player} player
   * @returns {Promise<Player>}
   */
  async update(player) {
    try {
      const updated = await PlayerModel.findByIdAndUpdate(
        player.id,
        {
          nickname: player.nickname,
          socketId: player.socketId,
          lobbyId: player.lobbyId,
          team: player.team.map(p => p.getCurrentState ? p.getCurrentState() : p),
          ready: player.ready,
          isActive: player.isActive
        },
        { new: true }
      );

      return this._mapToDomain(updated);
    } catch (error) {
      console.error('Error updating player:', error);
      throw error;
    }
  }

  /**
   * Elimina un jugador
   * @param {string} id
   * @returns {Promise<void>}
   */
  async delete(id) {
    try {
      await PlayerModel.findByIdAndDelete(id);
    } catch (error) {
      console.error('Error deleting player:', error);
      throw error;
    }
  }

  /**
   * Mapea un documento de MongoDB a una entidad Player del dominio
   * @private
   * @param {object} playerDoc
   * @returns {Player}
   */
  _mapToDomain(playerDoc) {
    const player = new Player(
      playerDoc._id.toString(),
      playerDoc.nickname,
      playerDoc.socketId,
      playerDoc.lobbyId ? playerDoc.lobbyId.toString() : null
    );
    player.team = (playerDoc.team || []).map(p => {
      const ps = new PokemonState(p.pokemonId, p.name, p.type, p.hp, p.attack, p.defense, p.speed, p.sprite, p.moves || []);
      ps.currentHp = p.currentHp !== undefined ? p.currentHp : p.hp;
      ps.defeated = p.defeated || false;
      return ps;
    });
    player.ready = playerDoc.ready;
    player.isActive = playerDoc.isActive;
    return player;
  }
}

module.exports = MongoPlayerRepository;
