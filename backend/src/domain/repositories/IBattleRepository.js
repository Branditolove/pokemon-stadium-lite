/**
 * IBattleRepository - Interfaz para persistencia de batallas
 */
class IBattleRepository {
  async save(battle) {
    throw new Error('Not implemented');
  }

  async findById(id) {
    throw new Error('Not implemented');
  }

  async findByLobbyId(lobbyId) {
    throw new Error('Not implemented');
  }

  async update(battle) {
    throw new Error('Not implemented');
  }

  async delete(id) {
    throw new Error('Not implemented');
  }
}

module.exports = IBattleRepository;
