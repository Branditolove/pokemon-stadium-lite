const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const { connectDatabase, disconnectDatabase } = require('./infrastructure/database/connection');
const createHealthRoutes = require('./infrastructure/http/routes/healthRoutes');
const SocketHandler = require('./interfaces/socket/SocketHandler');
const MongoPlayerRepository = require('./infrastructure/repositories/MongoPlayerRepository');
const MongoLobbyRepository = require('./infrastructure/repositories/MongoLobbyRepository');
const MongoBattleRepository = require('./infrastructure/repositories/MongoBattleRepository');

/**
 * Inicializa la aplicación Express con Socket.IO
 */
async function createApp() {
  const app = express();
  const httpServer = createServer(app);

  // Socket.IO configuration
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    },
    transports: ['websocket', 'polling']
  });

  // Middlewares
  app.use(cors());
  app.use(express.json());

  // Routes
  app.use(createHealthRoutes());

  // Error handling middleware (must be after routes)
  app.use((err, req, res, next) => {
    console.error('Express error:', err);
    res.status(500).json({
      error: 'Internal server error',
      message: err.message
    });
  });

  return {
    app,
    httpServer,
    io
  };
}

/**
 * Inicia el servidor
 */
async function startServer() {
  try {
    console.log('Starting Pokemon Stadium Lite backend...');

    // Conectar a MongoDB
    const mongodbUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/pokemon_stadium';
    await connectDatabase(mongodbUri);
    console.log('Database connected');

    // Crear aplicación
    const { app, httpServer, io } = await createApp();

    // Inicializar repositorios
    const playerRepository = new MongoPlayerRepository();
    const lobbyRepository = new MongoLobbyRepository();
    const battleRepository = new MongoBattleRepository();

    // Socket.IO connection handler
    const socketHandler = new SocketHandler(io, lobbyRepository, playerRepository, battleRepository);

    io.on('connection', (socket) => {
      console.log(`Client connected: ${socket.id}`);
      socketHandler.registerHandlers(socket);
    });

    // Iniciar servidor HTTP
    const PORT = process.env.PORT || 8080;
    const HOST = '0.0.0.0';

    httpServer.listen(PORT, HOST, () => {
      console.log(`Pokemon Stadium Lite backend listening on ${HOST}:${PORT}`);
    });

    // Manejo de señales de terminación
    const gracefulShutdown = async () => {
      console.log('Shutting down gracefully...');
      httpServer.close(() => {
        console.log('HTTP server closed');
      });

      io.close();
      console.log('Socket.IO server closed');

      await disconnectDatabase();
      process.exit(0);
    };

    process.on('SIGTERM', gracefulShutdown);
    process.on('SIGINT', gracefulShutdown);

  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Exportar funciones para testing
module.exports = {
  createApp,
  startServer
};

// Iniciar si se ejecuta directamente
if (require.main === module) {
  startServer();
}
