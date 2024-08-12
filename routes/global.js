const express = require('express');
const router = express.Router();
const db = require('../models'); // Importing the db

// Endpoint to get all users
router.get('/users', async (req, res) => {
  try {
    const users = await db.User.findAll(); // Fetch all users
    res.status(200).json(users); // Send users as JSON response
  } catch (error) {
    res.status(400).json({ error: error.message }); // Handle errors
  }
});

module.exports = router;