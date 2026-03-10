/**
 * Eventos de Socket.IO para Pokémon Stadium Lite
 * Define los nombres constantes de los eventos
 */

const EVENTS = {
  // Cliente -> Servidor
  JOIN_LOBBY: 'join_lobby',
  ASSIGN_POKEMON: 'assign_pokemon',
  READY: 'ready',
  ATTACK: 'attack',

  // Servidor -> Cliente
  LOBBY_STATUS: 'lobby_status',
  BATTLE_START: 'battle_start',
  TURN_RESULT: 'turn_result',
  BATTLE_END: 'battle_end',
  ERROR: 'error'
};

module.exports = EVENTS;
