import * as Sequelize from 'sequelize';
import sequelize from '../../../common/dbs/sequelize';
import FavoriteListsEntitiesRecord from './interfaces';

export interface FavoriteListsEntitiesInstance extends Sequelize.Instance<FavoriteListsEntitiesRecord> {
  dataValues: FavoriteListsEntitiesRecord;
}

export const scheme = sequelize.define<FavoriteListsEntitiesInstance, FavoriteListsEntitiesRecord>('FavoriteListsEntities', {
  entityId: {
    type: Sequelize.BIGINT,
    allowNull: false,
  },
  listId: {
    type: Sequelize.BIGINT,
    allowNull: false,
    references: {
      model: 'FavoriteLists',
      key: 'id',
    },
  },
  type: {
    type: Sequelize.STRING(16),
    allowNull: false,
  },
  note: {
    type: Sequelize.STRING(1000),
    allowNull: true,
    defaultValue: null,
  },
  createdAt: {
    type: Sequelize.DATE,
    defaultValue: Sequelize.literal('NOW()'),
  },
  updatedAt: {
    type: Sequelize.DATE,
    defaultValue: Sequelize.literal('NOW()'),
  },
}, {
  freezeTableName: true,
  timestamps: false,
});

scheme.removeAttribute('id');
