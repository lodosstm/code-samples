import * as Sequelize from 'sequelize';
import sequelize from '../../../common/dbs/sequelize';
import { FavoriteListsRecord } from './interfaces';

export interface FavoriteListsInstance extends Sequelize.Instance<FavoriteListsRecord> {
  dataValues: FavoriteListsRecord;
}

export const scheme = sequelize.define<FavoriteListsInstance, FavoriteListsRecord>('FavoriteLists', {
  id: {
    type: Sequelize.BIGINT,
    primaryKey: true,
    autoIncrement: true,
  },
  foodEnthusiastId: {
    type: Sequelize.BIGINT,
  },
  name: {
    type: Sequelize.STRING(128),
    allowNull: false,
  },
  createdAt: {
    type: Sequelize.DATE,
  },
}, {
  timestamps: false,
});
