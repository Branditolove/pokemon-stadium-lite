/**
 * ReadyUseCase - Caso de uso para marcar un jugador como listo
 */
class ReadyUseCase {
  constructor(playerRepository, lobbyRepository) {
    this.playerRepository = playerRepository;
    this.lobbyRepository = lobbyRepository;
  }

  /**
   * Ejecuta el caso de uso
   * @param {object} input - { playerId: string, lobbyId: string }
   * @returns {Promise<object>} - { player: Player, lobby: Lobby, canStartBattle: boolean }
   */
  async execute(input) {
    const { playerId, lobbyId } = input;

    if (!playerId || !lobbyId) {
      throw new Error('PlayerId and lobbyId are required');
    }

    // Obtener el jugador
    const player = await this.playerRepository.findById(playerId);
    if (!player) {
      throw new Error('Player not found');
    }

    // Verificar que el jugador tenga un equipo asignado
    if (!player.team || player.team.length === 0) {
      throw new Error('Player must have a team assigned before marking ready');
    }

    // Obtener el lobby
    const lobby = await this.lobbyRepository.findById(lobbyId);
    if (!lobby) {
      throw new Error('Lobby not found');
    }

    // Marcar al jugador como listo
    player.markAsReady();
    await this.playerRepository.update(player);

    // Actualizar el lobby
    const updatedLobby = await this.lobbyRepository.findById(lobbyId);

    // Verificar si ambos jugadores están listos (cargar jugadores completos para leer campo ready)
    let canStartBattle = false;
    if (updatedLobby.players.length === 2) {
      const allPlayers = await Promise.all(
        updatedLobby.players.map(p => this.playerRepository.findById(p.id))
      );
      updatedLobby.players = allPlayers;
      if (allPlayers.length === 2 && allPlayers.every(p => p && p.ready)) {
        updatedLobby.markAsReady();
        await this.lobbyRepository.update(updatedLobby);
        canStartBattle = true;
      }
    }

    return {
      player,
      lobby: updatedLobby,
      canStartBattle
    };
  }
}

module.exports = ReadyUseCase;
