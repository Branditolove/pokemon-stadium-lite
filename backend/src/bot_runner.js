/**
 * Bot runner in-process - evita spawn de procesos hijo
 * Se conecta al servidor vía socket.io-client dentro del mismo proceso Node
 */
const { io } = require('socket.io-client');

/**
 * Lanza un bot que se une al lobby y juega automáticamente
 * @param {object} opts
 * @param {string} opts.url       - URL del servidor (ej: http://localhost:8080)
 * @param {string} opts.nickname  - Nombre del bot (Toby, Gary, Brandon)
 * @param {string} opts.difficulty - easy | medium | brandon
 */
function spawnInProcessBot({ url, nickname, difficulty }) {
  const socket = io(url, {
    transports: ['polling'],
    reconnection: false,
  });

  let myPlayerId   = null;
  let isMyTurn     = false;
  let battleActive = false;
  let teamAssigned = false;
  let teamReceived = false;
  let readySent    = false;
  let myMoves      = [];

  socket.on('connect', () => {
    console.log(`🤖 Bot "${nickname}" conectado (${socket.id})`);
    socket.emit('join_lobby', { nickname });
  });

  socket.on('connect_error', (err) => {
    console.error(`🤖 Bot "${nickname}" error de conexión: ${err.message}`);
  });

  socket.on('lobby_status', (data) => {
    if (data.players && !myPlayerId) {
      const me = data.players.find(p => p.nickname === nickname);
      if (me) {
        myPlayerId = me._id || me.id;
        if (!teamAssigned) {
          teamAssigned = true;
          socket.emit('assign_pokemon', {});
        }
      }
    }

    if (data.players) {
      const me = data.players.find(p => p.nickname === nickname);
      if (me && me.team && me.team.length > 0 && !readySent) {
        teamReceived = true;
        readySent = true;
        console.log(`🤖 Bot "${nickname}" enviando ready...`);
        socket.emit('ready');
      }
    }
  });

  socket.on('battle_start', (data) => {
    battleActive = true;
    console.log(`🤖 Bot "${nickname}" ¡Batalla iniciada!`);

    if (data.teams) {
      const myTeam = data.teams.find(t => t.playerId === myPlayerId);
      if (myTeam && myTeam.team && myTeam.team.length > 0) {
        myMoves = myTeam.team[0].moves || [];
      }
    }

    const firstTurn = data.currentTurn;
    isMyTurn = firstTurn === myPlayerId || firstTurn === nickname;
    if (isMyTurn) attackAfterDelay();
  });

  socket.on('turn_result', (data) => {
    if (data.newPokemon && data.newPokemon.moves) {
      myMoves = data.newPokemon.moves;
    }
    const nextTurn = data.nextTurn;
    isMyTurn = nextTurn === myPlayerId || nextTurn === nickname;
    if (isMyTurn && battleActive) attackAfterDelay();
  });

  socket.on('battle_end', () => {
    battleActive = false;
    console.log(`🤖 Bot "${nickname}" batalla terminada, desconectando...`);
    setTimeout(() => socket.disconnect(), 2000);
  });

  socket.on('error', (data) => {
    console.error(`🤖 Bot "${nickname}" error: ${data.message || data}`);
  });

  function selectMove() {
    if (!myMoves || myMoves.length === 0) return 'tackle';
    if (difficulty === 'easy') {
      return myMoves[Math.floor(Math.random() * myMoves.length)].name;
    }
    const best = myMoves.reduce((a, b) => (b.power || 0) > (a.power || 0) ? b : a);
    return best.name;
  }

  function attackAfterDelay() {
    let delay;
    if (difficulty === 'easy') {
      delay = 3000 + Math.random() * 2000;
      if (Math.random() < 0.30) delay += 4000;
    } else if (difficulty === 'brandon') {
      delay = 300 + Math.random() * 300;
    } else {
      delay = 1200 + Math.random() * 1000;
    }

    setTimeout(() => {
      if (isMyTurn && battleActive) {
        const moveName = selectMove();
        console.log(`🤖 Bot "${nickname}" usa ${moveName}!`);
        socket.emit('attack', { moveName });
      }
    }, delay);
  }
}

module.exports = { spawnInProcessBot };
