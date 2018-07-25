const Sequelize = require('sequelize');
const sequelize = require('../../../lib/sequelize');

const Project = sequelize.define('Projects', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  title: {
    type: Sequelize.STRING(255),
    allowNull: false,
    unique: true,
  },
  managerId: {
    type: Sequelize.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  estimatedTime: {
    type: Sequelize.FLOAT,
  },
  isDirectContract: {
    type: Sequelize.BOOLEAN,
    allowNull: false,
    defaultValue: false,
  },
  startDate: {
    type: Sequelize.DATE,
    defaultValue: Sequelize.literal('NOW()'),
  },
  endDate: {
    type: Sequelize.DATE,
  },
  status: {
    type: Sequelize.ENUM('opened', 'closed'),
    allowNull: false,
  },
  createdAt: {
    type: Sequelize.DATE,
    defaultValue: Sequelize.literal('NOW()'),
  },
  updatedAt: {
    type: Sequelize.DATE,
    defaultValue: Sequelize.literal('NOW()'),
  },
}, { timestamps: false });

module.exports = Project;
