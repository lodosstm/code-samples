const Sequelize = require('sequelize');
const sequelize = require('../../../lib/sequelize');

const Title = sequelize.define('Titles', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  name: {
    type: Sequelize.STRING(255),
    unique: true,
    allowNull: false,
  },
  createdAt: {
    type: Sequelize.DATE,
    defaultValue: Sequelize.literal('NOW()'),
  },
}, { timestamps: false });

module.exports = Title;
