const mongoose = require('mongoose');

const turnSchema = new mongoose.Schema({
  attacker: mongoose.Schema.Types.ObjectId,
  defender: mongoose.Schema.Types.ObjectId,
  damage: Number,
  timestamp: { type: Date, default: Date.now }
}, { _id: false });

const battleSchema = new mongoose.Schema({
  lobbyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lobby',
    required: true
  },
  turns: [turnSchema],
  winner: mongoose.Schema.Types.ObjectId,
  startedAt: { type: Date, default: Date.now },
  endedAt: Date
});

const BattleModel = mongoose.model('Battle', battleSchema);

module.exports = BattleModel;
