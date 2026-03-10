const Player = require('../../domain/entities/Player');
const Lobby = require('../../domain/entities/Lobby');

/**
 * JoinLobbyUseCase - Caso de uso para que un jugador se una al lobby
 */
class JoinLobbyUseCase {
  constructor(lobbyRepository, playerRepository) {
    this.lobbyRepository = lobbyRepository;
    this.playerRepository = playerRepository;
  }

  /**
   * Ejecuta el caso de uso
   * @param {object} input - { nickname: string, socketId: string }
   * @returns {Promise<object>} - { lobby: Lobby, player: Player }
   */
  async execute(input) {
    const { nickname, socketId } = input;

    // Validación
    if (!nickname || !socketId) {
      throw new Error('Nickname and socketId are required');
    }

    // Buscar o crear el lobby global
    let lobby = await this.lobbyRepository.findGlobalLobby();

    if (!lobby) {
      // Crear nuevo lobby
      lobby = new Lobby(null);
      await this.lobbyRepository.save(lobby);
    }

    // Verificar que el lobby no esté lleno
    if (lobby.isFull()) {
      throw new Error('Lobby is full');
    }

    // Crear nuevo jugador
    const player = new Player(null, nickname, socketId, lobby.id);
    await this.playerRepository.save(player);

    // Añadir jugador al lobby
    lobby.addPlayer(player);
    await this.lobbyRepository.update(lobby);

    return {
      lobby,
      player
    };
  }
}

module.exports = JoinLobbyUseCase;
