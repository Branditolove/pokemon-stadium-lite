const express = require('express');

/**
 * Health check routes
 */
function createHealthRoutes() {
  const router = express.Router();

  /**
   * GET /health - Health check endpoint
   */
  router.get('/health', (req, res) => {
    res.status(200).json({
      status: 'ok',
      message: 'Pokemon Stadium Lite backend is running',
      timestamp: new Date().toISOString()
    });
  });

  return router;
}

module.exports = createHealthRoutes;
