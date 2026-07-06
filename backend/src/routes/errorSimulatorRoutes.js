const express = require('express');
const router = express.Router();
const instana = require('@instana/collector');

// POST /api/simulate-error
// Body: { statusCode: number, message: string }
router.post('/', (req, res) => {
  const statusCode = parseInt(req.body.statusCode, 10) || 500;
  const message = req.body.message || 'Simulated error';

  // Mark the Instana span as erroneous so it shows up in error dashboards
  const currentSpan = instana.currentSpan();
  if (currentSpan) {
    currentSpan.markAsErroneous(new Error(message));
  }

  console.error(`[simulate-error] ${statusCode}: ${message}`);
  res.status(statusCode).json({ error: message, simulated: true });
});

module.exports = router;

// Made with Bob
