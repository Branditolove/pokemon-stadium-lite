/**
 * IPlayerRepository - Interfaz para persistencia de jugadores
 */
class IPlayerRepository {
  async save(player) {
    throw new Error('Not implemented');
  }

  async findById(id) {
    throw new Error('Not implemented');
  }

  async findByNickname(nickname) {
    throw new Error('Not implemented');
  }

  async update(player) {
    throw new Error('Not implemented');
  }

  async delete(id) {
    throw new Error('Not implemented');
  }
}

module.exports = IPlayerRepository;
