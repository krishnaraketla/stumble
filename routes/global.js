const express = require('express');
const router = express.Router();
const db = require('../models');
const { Sequelize } = require('sequelize');

// Endpoint to get all users using raw SQL
router.get('/users', async (req, res) => {
  try {
    // Using raw SQL to fetch all users
    const users = await db.sequelize.query(
      `SELECT * FROM "Users";`,
      {
        type: Sequelize.QueryTypes.SELECT
      }
    );

    res.status(200).json(users); // Send users as JSON response
  } catch (error) {
    res.status(400).json({ error: error.message }); // Handle errors
  }
});

module.exports = router;