/**
 * 🤖 Bot Player - Simula un segundo jugador para pruebas
 * Uso: node bot_player.js [url] [nickname] [difficulty]
 * difficulty: easy | medium | brandon
 */

const { io } = require('socket.io-client');

const URL        = process.argv[2] || 'http://localhost:8080';
const NICKNAME   = process.argv[3] || 'Gary';
const DIFFICULTY = process.argv[4] || 'medium'; // easy | medium | brandon

console.log(`\n🤖 Bot "${NICKNAME}" [${DIFFICULTY}] conectando a ${URL}...\n`);

const socket = io(URL, {
  transports: ['websocket'],
  reconnection: false,
});

let myPlayerId  = null;
let isMyTurn    = false;
let battleActive = false;
let teamAssigned = false;
let readySent    = false;
let myMoves      = [];

// ─── Conexión ───────────────────────────────────────────────
socket.on('connect', () => {
  console.log(`✅ Conectado (socket: ${socket.id})`);
  console.log(`📨 Enviando join_lobby con nickname: ${NICKNAME}`);
  socket.emit('join_lobby', { nickname: NICKNAME });
});

// ─── Lobby Status ────────────────────────────────────────────
socket.on('lobby_status', (data) => {
  console.log(`\n📊 lobby_status: ${data.status}`);

  if (data.players && !myPlayerId) {
    const me = data.players.find(p => p.nickname === NICKNAME);
    if (me) {
      myPlayerId = me._id || me.id;
      console.log(`   → Yo soy: ${NICKNAME} (id: ${myPlayerId})`);

      if (!teamAssigned) {
        teamAssigned = true;
        console.log('📨 Enviando assign_pokemon (random)...');
        socket.emit('assign_pokemon', {});
      }
    }
  }

  if (data.players) {
    data.players.forEach(p => {
      console.log(`   👤 ${p.nickname} - ready: ${p.ready}`);
    });

    const me = data.players.find(p => p.nickname === NICKNAME);
    if (me && me.team && me.team.length > 0 && !readySent) {
      readySent = true;
      console.log('📨 Enviando ready...');
      socket.emit('ready');
    }
  }
});

// ─── Battle Start ────────────────────────────────────────────
socket.on('battle_start', (data) => {
  console.log('\n⚔️  ¡BATALLA INICIADA!');
  battleActive = true;

  if (data.teams) {
    const myTeam = data.teams.find(t => t.playerId === myPlayerId);
    if (myTeam && myTeam.team && myTeam.team.length > 0) {
      myMoves = myTeam.team[0].moves || [];
      console.log(`   → Mis moves: ${myMoves.map(m => m.name).join(', ')}`);
    }
  }

  const firstTurn = data.currentTurn;
  isMyTurn = firstTurn === myPlayerId || firstTurn === NICKNAME;
  console.log(`   → Primer turno: ${firstTurn}`);
  console.log(`   → ¿Es mi turno? ${isMyTurn ? 'SÍ ⚡' : 'NO, espero...'}`);

  if (isMyTurn) attackAfterDelay();
});

// ─── Turn Result ─────────────────────────────────────────────
socket.on('turn_result', (data) => {
  console.log(`\n💥 turn_result:`);
  console.log(`   Atacante: ${data.attacker}`);
  console.log(`   Daño: ${data.damage}`);
  console.log(`   HP restante: ${data.defenderCurrentHp}`);

  if (data.pokemonDefeated) console.log('   💀 Pokémon derrotado!');
  if (data.newPokemon) {
    const name = data.newPokemon.name || data.newPokemon;
    console.log(`   🔄 Nuevo Pokémon: ${name}`);
    if (data.newPokemon.moves) myMoves = data.newPokemon.moves;
  }

  const nextTurn = data.nextTurn;
  isMyTurn = nextTurn === myPlayerId || nextTurn === NICKNAME;
  console.log(`   → Siguiente turno: ¿Yo? ${isMyTurn ? 'SÍ ⚡' : 'NO'}`);

  if (isMyTurn && battleActive) attackAfterDelay();
});

// ─── Battle End ──────────────────────────────────────────────
socket.on('battle_end', (data) => {
  battleActive = false;
  const winner = data.winner;
  console.log(`\n🏆 ¡BATALLA TERMINADA!`);
  console.log(`   Ganador: ${winner}`);

  if (winner === NICKNAME || winner === myPlayerId) {
    console.log('   🎉 ¡GANÉ!');
    if (DIFFICULTY === 'brandon') {
      console.log('   😎 Brandon: "Jaja, me contrataron para esto."');
    }
  } else {
    console.log('   😢 Perdí...');
  }

  setTimeout(() => { socket.disconnect(); process.exit(0); }, 2000);
});

// ─── Error ───────────────────────────────────────────────────
socket.on('error', (data) => {
  console.error(`\n❌ Error: ${data.message || data}`);
});

socket.on('connect_error', (err) => {
  console.error(`\n❌ Error de conexión: ${err.message}`);
  process.exit(1);
});

socket.on('disconnect', () => {
  console.log('\n🔌 Bot desconectado.');
});

// ─── Helper: selecciona move según dificultad ─────────────────
function selectMove() {
  if (!myMoves || myMoves.length === 0) return 'tackle';

  if (DIFFICULTY === 'easy') {
    // Fácil: move aleatorio
    return myMoves[Math.floor(Math.random() * myMoves.length)].name;
  }

  // Medio y Brandon: move con mayor power
  const best = myMoves.reduce((a, b) => (b.power || 0) > (a.power || 0) ? b : a);
  return best.name;
}

// ─── Helper: atacar con delay según dificultad ───────────────
function attackAfterDelay() {
  let delay;

  if (DIFFICULTY === 'easy') {
    delay = 3000 + Math.random() * 2000; // 3–5s
    // 30% chance de "dudar" extra
    if (Math.random() < 0.30) delay += 4000;
  } else if (DIFFICULTY === 'brandon') {
    delay = 300 + Math.random() * 300;   // 0.3–0.6s (implacable)
  } else {
    delay = 1200 + Math.random() * 1000; // 1.2–2.2s (medio)
  }

  console.log(`   ⏳ Bot atacando en ${(delay / 1000).toFixed(1)}s...`);

  setTimeout(() => {
    if (isMyTurn && battleActive) {
      const moveName = selectMove();
      console.log(`   ⚡ ${NICKNAME} usa ${moveName}!`);
      socket.emit('attack', { moveName });
    }
  }, delay);
}
