/**
 * ILobbyRepository - Interfaz para persistencia de lobbies
 */
class ILobbyRepository {
  async save(lobby) {
    throw new Error('Not implemented');
  }

  async findById(id) {
    throw new Error('Not implemented');
  }

  async findGlobalLobby() {
    throw new Error('Not implemented');
  }

  async update(lobby) {
    throw new Error('Not implemented');
  }

  async delete(id) {
    throw new Error('Not implemented');
  }
}

module.exports = ILobbyRepository;
