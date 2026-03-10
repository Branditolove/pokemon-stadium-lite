const mongoose = require('mongoose');

const moveSchema = new mongoose.Schema({
  name: String,
  power: Number,
  type: String,
  pp: Number
}, { _id: false });

const pokemonStateSchema = new mongoose.Schema({
  pokemonId: Number,
  name: String,
  type: { type: [String] },
  hp: Number,
  currentHp: Number,
  attack: Number,
  defense: Number,
  speed: Number,
  sprite: String,
  defeated: { type: Boolean, default: false },
  moves: { type: [moveSchema], default: [] }
}, { _id: false });

const playerSchema = new mongoose.Schema({
  nickname: { type: String, required: true },
  socketId: String,
  lobbyId: mongoose.Schema.Types.ObjectId,
  team: [pokemonStateSchema],
  ready: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now }
});

const PlayerModel = mongoose.model('Player', playerSchema);

module.exports = PlayerModel;
