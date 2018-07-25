import { NextFunction } from 'express';
import {
  addPickedEntity,
  removePickedEntity,
  updateEntityNote,
  getEntityNote,
} from '../models/favorite-lists-entities';
import {
  addFavoriteList,
  getFavoriteListDetailsById,
  getFavoriteListByName,
  getFavoriteLists,
  updateFavoriteList,
  removeFavoriteList,
  getFavoriteListById,
  isUserListOwner,
} from '../models/favorite-lists';
import { FavoriteListsRecord as FavoriteList } from '../models/favorite-lists/interfaces';
import * as Events from '../models/events';
import * as Openings from '../models/openings';
import * as User from '../models/user';
import AccessDenied from '../errors/access-denied';
import FavoriteListIsNotExist from '../errors/favorite-lists/favorite-list-is-not-exist';
import FavoriteListAlreadyExist from '../errors/favorite-lists/favorite-list-already-exist';
import FavoriteListNameAlreadyExist from '../errors/favorite-lists/favorite-list-name-already-exist';
import BusinessUserIsNotFound from '../errors/admin-business-user-in-not-found';
import EventIsNotFound from '../errors/event-is-not-found';
import OpeningIsNotFound from '../errors/opening-is-not-found';
import TheSameListItem from '../errors/favorite-lists/favorite-list-the-same-list-item';
import * as Bluebird from 'bluebird';

interface EntityDataInterface {
  [key: string]: {
    isExist: (id: number) => Promise<number|null>|Bluebird<any>;
    EntityIsNotFound: any;
  };
}

const EntityData: EntityDataInterface = {
  businesses: {
    isExist: User.getInternalId,
    EntityIsNotFound: BusinessUserIsNotFound,
  },
  events: {
    isExist: Events.getEventById,
    EntityIsNotFound: EventIsNotFound,
  },
  openings: {
    isExist: Openings.getOpeningById,
    EntityIsNotFound: OpeningIsNotFound,
  },
};

export const createList = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    body: {
      listName,
    },
  } = req;
  const existingList = await getFavoriteListByName(listName, foodEnthusiastId);

  if (existingList) {
    next(new FavoriteListAlreadyExist());

    return;
  }

  return addFavoriteList(listName, foodEnthusiastId)
    .then(res.reply);
};

export const getListDetailsById = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      id,
    },
  } = req;
  const list: FavoriteList | null = await getFavoriteListDetailsById(id);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  res.reply({ id: list.id, name: list.name });
};

export const getLists = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    query: {
      isEntityExists,
    },
  } = req;
  const favoriteList = await getFavoriteLists(foodEnthusiastId, isEntityExists);

  res.reply(favoriteList);
};

export const updateList = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      id,
    },
    body: {
      listName,
    },
  } = req;
  const list = await getFavoriteListDetailsById(id);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  const existingListName = await getFavoriteListByName(listName, foodEnthusiastId);

  if (existingListName) {
    next(new FavoriteListNameAlreadyExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  return updateFavoriteList(id, listName)
    .then(res.reply);
};

export const deleteList = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      id,
    },
  } = req;
  const list: FavoriteList | null = await getFavoriteListDetailsById(id);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  return removeFavoriteList(id)
    .then(res.success);
};

export const addFavoriteEntity = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      id: listId,
      type,
    },
    body: {
      entityId,
    },
  } = req;
  const list = await getFavoriteListDetailsById(listId);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  const {
    EntityIsNotFound,
    isExist,
  } = EntityData[type];

  if (!(await isExist(entityId))) {
    next(new EntityIsNotFound());

    return;
  }

  try {
    await addPickedEntity(listId, entityId, type);
  } catch (err) {
    if (err.name === 'SequelizeUniqueConstraintError') {
      next(new TheSameListItem());

      return;
    }

    throw err;
  }

  res.success();
};

export const removeFavoriteEntity = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      listId,
      entityId,
      type,
    },
  } = req;
  const list: FavoriteList | null = await getFavoriteListDetailsById(listId);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  await removePickedEntity(listId, entityId, type);

  res.success();
};

export const updateFavoriteEntityNote = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      listId,
      type,
      entityId,
    },
    body: {
      note,
    },
  } = req;
  const list = await getFavoriteListDetailsById(listId);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  return updateEntityNote(listId, entityId, type, note)
    .then(res.success);
};

export const getFavoriteEntityNote = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastId,
    },
    params: {
      listId,
      type,
      entityId,
    },
  } = req;
  const list: FavoriteList | null = await getFavoriteListDetailsById(listId);

  if (!list) {
    next(new FavoriteListIsNotExist());

    return;
  }

  if (list.foodEnthusiastId !== foodEnthusiastId) {
    next(new AccessDenied());

    return;
  }

  return getEntityNote(listId, entityId, type)
    .then(res.reply);
};

export const getFavoriteList = async (req: App.Request, res: App.Endpoint, next: NextFunction) => {
  const {
    userSession: {
      internalId: foodEnthusiastInternalId,
    },
    params: {
      id: listId,
    },
    query: {
      order: orderingMethod,
      limit,
      firstEntity,
      inRectangle,
      geoPosition,
    },
  } = req;
  const isUserOwner = await isUserListOwner(listId, foodEnthusiastInternalId);

  if (!isUserOwner) {
    next(new AccessDenied());

    return;
  }

  const listItems = await getFavoriteListById(listId, orderingMethod, limit, inRectangle, firstEntity, geoPosition);

  res.reply(listItems);
};
