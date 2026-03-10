/**
 * AttackUseCase - Caso de uso para ejecutar un ataque en batalla
 */
class AttackUseCase {
  constructor(playerRepository, lobbyRepository, battleRepository) {
    this.playerRepository = playerRepository;
    this.lobbyRepository = lobbyRepository;
    this.battleRepository = battleRepository;
  }

  /**
   * Ejecuta el caso de uso
   * @param {object} input - { playerId: string, lobbyId: string }
   * @returns {Promise<object>} - { damage: number, defenderCurrentHp: number, pokemonDefeated: boolean, newPokemon: object|null, nextTurn: string, battleEnded: boolean, winner: string|null }
   */
  async execute(input) {
    const { playerId, lobbyId, moveName } = input;

    if (!playerId || !lobbyId) {
      throw new Error('PlayerId and lobbyId are required');
    }

    // Obtener el lobby
    const lobby = await this.lobbyRepository.findById(lobbyId);
    if (!lobby) {
      throw new Error('Lobby not found');
    }

    // Verificar que el lobby está en batalla
    if (lobby.status !== 'battling') {
      throw new Error('Battle is not in progress');
    }

    // Verificar que es el turno del jugador
    if (lobby.currentTurn !== playerId) {
      throw new Error('It is not your turn');
    }

    // Verificar que no hay un turno siendo procesado (atomic turn)
    if (lobby.processingTurn) {
      throw new Error('Turn is being processed, please wait');
    }

    // Marcar que se está procesando un turno
    lobby.processingTurn = true;
    await this.lobbyRepository.update(lobby);

    try {
      // Obtener atacante y defensor
      const attacker = await this.playerRepository.findById(playerId);
      const defenderRef = lobby.getOpponent(playerId);

      if (!attacker || !defenderRef) {
        throw new Error('Invalid players in battle');
      }

      const defender = await this.playerRepository.findById(defenderRef.id);
      if (!defender) {
        throw new Error('Defender not found');
      }

      // Obtener Pokémon activos
      const attackerPokemon = attacker.getActivePokemon();
      const defenderPokemon = defender.getActivePokemon();

      if (!attackerPokemon || !defenderPokemon) {
        throw new Error('Missing active pokemon');
      }

      // Buscar el move seleccionado (o usar power=40 como fallback)
      let movePower = 40;
      let usedMoveName = moveName || 'tackle';
      if (moveName && attackerPokemon.moves && attackerPokemon.moves.length > 0) {
        const move = attackerPokemon.moves.find(m => m.name === moveName);
        if (move) movePower = move.power || 40;
      }

      // Nueva fórmula: max(5, floor(attack * power / (2 * defense)))
      let damage = Math.max(5, Math.floor(attackerPokemon.attack * movePower / (2 * defenderPokemon.defense)));

      // Brandon mode: daño masivo, siempre gana 😎
      if (attacker.nickname === 'Brandon') {
        damage = Math.max(damage * 5, defenderPokemon.currentHp);
      }

      // Aplicar daño al Pokémon del defensor
      defenderPokemon.takeDamage(damage);
      const defenderCurrentHp = defenderPokemon.currentHp;
      const pokemonDefeated = defenderPokemon.isDefeated();

      // Actualizar el defensor
      await this.playerRepository.update(defender);

      // Registrar el turno en la batalla
      const battle = await this.battleRepository.findByLobbyId(lobbyId);
      if (battle) {
        battle.recordTurn({
          attacker: playerId,
          defender: defender.id,
          moveName: usedMoveName,
          damage: damage,
          timestamp: new Date()
        });
        await this.battleRepository.update(battle);
      }

      let newPokemon = null;
      let battleEnded = false;
      let winner = null;

      // Verificar si el Pokémon del defensor fue derrotado
      if (pokemonDefeated) {
        const nextActivePokemon = defender.getActivePokemon();
        if (nextActivePokemon) {
          // El defensor tiene otro Pokémon
          newPokemon = nextActivePokemon.getCurrentState();
        } else {
          // El defensor no tiene más Pokémon - Fin de batalla
          battleEnded = true;
          winner = playerId;
          lobby.endBattle(winner);
          await this.lobbyRepository.update(lobby);

          if (battle) {
            battle.setWinner(winner);
            await this.battleRepository.update(battle);
          }
        }
      }

      // Cambiar el turno al siguiente jugador
      if (!battleEnded) {
        lobby.switchTurn();
        lobby.processingTurn = false;
        await this.lobbyRepository.update(lobby);
      }

      return {
        damage,
        moveName: usedMoveName,
        defenderCurrentHp,
        pokemonDefeated,
        newPokemon,
        nextTurn: lobby.currentTurn,
        battleEnded,
        winner
      };
    } catch (error) {
      // Liberar el flag de turno en caso de error
      lobby.processingTurn = false;
      await this.lobbyRepository.update(lobby);
      throw error;
    }
  }
}

module.exports = AttackUseCase;
