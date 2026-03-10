const mongoose = require('mongoose');

/**
 * Conecta a la base de datos MongoDB
 * @param {string} mongodbUri - URI de conexión a MongoDB
 * @returns {Promise<void>}
 */
async function connectDatabase(mongodbUri) {
  try {
    await mongoose.connect(mongodbUri);
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    throw error;
  }
}

/**
 * Desconecta de MongoDB
 * @returns {Promise<void>}
 */
async function disconnectDatabase() {
  try {
    await mongoose.disconnect();
    console.log('MongoDB disconnected');
  } catch (error) {
    console.error('MongoDB disconnection error:', error);
    throw error;
  }
}

module.exports = {
  connectDatabase,
  disconnectDatabase
};
