// /models/index.js
const { Sequelize } = require('sequelize');
const UserModel = require('./user');

const sequelize = new Sequelize(process.env.DATABASE_URL);

const User = UserModel(sequelize, Sequelize);

sequelize.sync()
  .then(() => {
    console.log('Database & tables created!');
  });

module.exports = {
  User,
  sequelize,
};