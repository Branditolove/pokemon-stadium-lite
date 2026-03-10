const ILobbyRepository = require('../../domain/repositories/ILobbyRepository');
const LobbyModel = require('../database/models/LobbyModel');
const Lobby = require('../../domain/entities/Lobby');

/**
 * MongoLobbyRepository - Implementación de persistencia de lobbies con MongoDB
 */
class MongoLobbyRepository extends ILobbyRepository {
  /**
   * Guarda un lobby en la base de datos
   * @param {Lobby} lobby
   * @returns {Promise<Lobby>}
   */
  async save(lobby) {
    try {
      const lobbyDoc = new LobbyModel({
        status: lobby.status,
        players: lobby.players.map(p => p.id),
        currentTurn: lobby.currentTurn,
        winner: lobby.winner
      });

      const saved = await lobbyDoc.save();
      lobby.id = saved._id.toString();
      return lobby;
    } catch (error) {
      console.error('Error saving lobby:', error);
      throw error;
    }
  }

  /**
   * Busca un lobby por ID
   * @param {string} id
   * @returns {Promise<Lobby|null>}
   */
  async findById(id) {
    try {
      const lobbyDoc = await LobbyModel.findById(id);
      if (!lobbyDoc) return null;

      return this._mapToDomain(lobbyDoc);
    } catch (error) {
      console.error('Error finding lobby by ID:', error);
      throw error;
    }
  }

  /**
   * Busca el lobby global (el único que debe existir)
   * @returns {Promise<Lobby|null>}
   */
  async findGlobalLobby() {
    try {
      // Only find lobbies in 'waiting' state (joinable).
      // 'ready', 'battling' and 'finished' lobbies are not joinable.
      const lobbyDoc = await LobbyModel.findOne({
        status: 'waiting'
      });
      if (!lobbyDoc) return null;

      return this._mapToDomain(lobbyDoc);
    } catch (error) {
      console.error('Error finding global lobby:', error);
      throw error;
    }
  }

  /**
   * Actualiza un lobby
   * @param {Lobby} lobby
   * @returns {Promise<Lobby>}
   */
  async update(lobby) {
    try {
      const updated = await LobbyModel.findByIdAndUpdate(
        lobby.id,
        {
          status: lobby.status,
          players: lobby.players.map(p => p.id),
          currentTurn: lobby.currentTurn,
          winner: lobby.winner
        },
        { new: true }
      );

      return this._mapToDomain(updated);
    } catch (error) {
      console.error('Error updating lobby:', error);
      throw error;
    }
  }

  /**
   * Elimina un lobby
   * @param {string} id
   * @returns {Promise<void>}
   */
  async delete(id) {
    try {
      await LobbyModel.findByIdAndDelete(id);
    } catch (error) {
      console.error('Error deleting lobby:', error);
      throw error;
    }
  }

  /**
   * Mapea un documento de MongoDB a una entidad Lobby del dominio
   * @private
   * @param {object} lobbyDoc
   * @returns {Lobby}
   */
  _mapToDomain(lobbyDoc) {
    const lobby = new Lobby(lobbyDoc._id.toString());
    lobby.status = lobbyDoc.status;
    lobby.players = lobbyDoc.players.map(id => ({ id: id.toString() }));
    lobby.currentTurn = lobbyDoc.currentTurn ? lobbyDoc.currentTurn.toString() : null;
    lobby.winner = lobbyDoc.winner ? lobbyDoc.winner.toString() : null;
    lobby.createdAt = lobbyDoc.createdAt;
    return lobby;
  }
}

module.exports = MongoLobbyRepository;
