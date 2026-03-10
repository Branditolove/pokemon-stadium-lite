/**
 * PokemonState Entity - Representa el estado de un pokémon en batalla
 */
class PokemonState {
  constructor(pokemonId, name, type, hp, attack, defense, speed, sprite, moves = []) {
    this.pokemonId = pokemonId;
    this.name = name;
    this.type = type;
    this.hp = hp; // HP máximo
    this.currentHp = hp; // HP actual en batalla
    this.attack = attack;
    this.defense = defense;
    this.speed = speed;
    this.sprite = sprite;
    this.defeated = false;
    this.moves = moves; // [{ name, power, type, pp }]
  }

  /**
   * Reduce el HP actual del pokémon
   * @param {number} damage - Daño a aplicar
   */
  takeDamage(damage) {
    this.currentHp = Math.max(0, this.currentHp - damage);
    if (this.currentHp === 0) {
      this.defeated = true;
    }
  }

  /**
   * Verifica si el pokémon está derrotado
   * @returns {boolean}
   */
  isDefeated() {
    return this.defeated;
  }

  /**
   * Obtiene la información actual del pokémon
   * @returns {object}
   */
  getCurrentState() {
    return {
      pokemonId: this.pokemonId,
      name: this.name,
      type: this.type,
      hp: this.hp,
      currentHp: this.currentHp,
      attack: this.attack,
      defense: this.defense,
      speed: this.speed,
      sprite: this.sprite,
      defeated: this.defeated,
      moves: this.moves
    };
  }
}

module.exports = PokemonState;
