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
    this.activePokemonName = null; // pokemon activo elegido por el jugador
  }

  /**
   * Añade un pokémon al equipo del jugador
   * @param {PokemonState} pokemonState
   */
  addPokemonToTeam(pokemonState) {
    this.team.push(pokemonState);
  }

  /**
   * Obtiene el pokémon activo.
   * Si el jugador eligió uno (activePokemonName), lo usa.
   * Si ese está derrotado o no existe, vuelve al primero vivo.
   * @returns {PokemonState|null}
   */
  getActivePokemon() {
    if (this.activePokemonName) {
      const named = this.team.find(p => p.name === this.activePokemonName && !p.defeated);
      if (named) return named;
      // El pokemon elegido fue derrotado, limpiar selección
      this.activePokemonName = null;
    }
    return this.team.find(pokemon => !pokemon.defeated) || null;
  }

  /**
   * Establece el pokémon activo por nombre (elección del jugador)
   * @param {string} name
   */
  setActivePokemon(name) {
    this.activePokemonName = name;
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
