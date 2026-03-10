/**
 * Player Entity - Representa a un jugador en el lobby
 */
class Player {
  constructor(id, nickname, socketId, lobbyId) {
    this.id = id;
    this.nickname = nickname;
    this.socketId = socketId;
    this.lobbyId = lobbyId;
    this.team = []; // Array de PokemonState
    this.ready = false;
    this.isActive = true;
  }

  /**
   * Añade un pokémon al equipo del jugador
   * @param {PokemonState} pokemonState
   */
  addPokemonToTeam(pokemonState) {
    this.team.push(pokemonState);
  }

  /**
   * Obtiene el pokémon activo (el primero no derrotado)
   * @returns {PokemonState|null}
   */
  getActivePokemon() {
    return this.team.find(pokemon => !pokemon.defeated) || null;
  }

  /**
   * Marca el jugador como listo
   */
  markAsReady() {
    this.ready = true;
  }

  /**
   * Obtiene todos los pokémon del jugador
   * @returns {Array}
   */
  getPokemonTeam() {
    return this.team;
  }

  /**
   * Verifica si el jugador tiene al menos un pokémon sin derrotar
   * @returns {boolean}
   */
  hasActivePokemon() {
    return this.getActivePokemon() !== null;
  }

  /**
   * Marca al jugador como inactivo
   */
  markAsInactive() {
    this.isActive = false;
  }
}

module.exports = Player;
