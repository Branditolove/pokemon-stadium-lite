const mongoose = require('mongoose');

const lobbySchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ['waiting', 'ready', 'battling', 'finished'],
    default: 'waiting'
  },
  players: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Player'
    }
  ],
  currentTurn: mongoose.Schema.Types.ObjectId,
  winner: mongoose.Schema.Types.ObjectId,
  processingTurn: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const LobbyModel = mongoose.model('Lobby', lobbySchema);

module.exports = LobbyModel;
