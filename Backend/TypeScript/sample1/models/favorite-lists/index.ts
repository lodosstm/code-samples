import {
  prop,
  pick,
} from 'ramda';
import {
  literal,
  FindOptionsAttributesArray,
  QueryTypes,
} from 'sequelize';
import { scheme as FavoriteLists } from './scheme';
import {
  FavoriteListsRecord as FavoriteList,
  IsEntityExistsData,
} from './interfaces';
import { removeAllPickedEntities } from '../favorite-lists-entities';
import sequelize from '../../../common/dbs/sequelize';
import {
  parseGeoPositionBusiness,
} from '../user';

export const addFavoriteList = (name: string, foodEnthusiastId: number) =>
  FavoriteLists.create({ foodEnthusiastId, name } as FavoriteList)
    .then<FavoriteList>(prop('dataValues'));

export const removeFavoriteList = (id: number) =>
  sequelize.transaction(async (transaction) => {
    await removeAllPickedEntities(id);

    return FavoriteLists.destroy({ where: { id } });
  });

export const updateFavoriteList = async (id: number, name: string) => {
  const [, favoriteList] = await FavoriteLists.update({name} as FavoriteList, {
    where: { id },
    returning: true,
  });

  return favoriteList[0];
};

export const getFavoriteListDetailsById = (id: number) =>
  FavoriteLists.find({ where: { id } })
    .then<FavoriteList | null>((favoriteList: any) => {
      return favoriteList ? prop('dataValues', favoriteList) : null;
    });

export const getFavoriteListByName = (name: string, foodEnthusiastId: number) =>
  FavoriteLists.find({ where: { name, foodEnthusiastId } })
    .then<FavoriteList | null>((favoriteList: any) => {
      return favoriteList ? prop('dataValues', favoriteList) : null;
    });

export const getFavoriteLists = (foodEnthusiastId: number, isEntityExists?: IsEntityExistsData) => {
  const isEntityExistsAttr = isEntityExists && [
    literal(`(
      SELECT COUNT("listId")::int::boolean
      FROM "FavoriteListsEntities"
      WHERE "FavoriteListsEntities"."entityId" = ${isEntityExists.entityId}
      AND "FavoriteListsEntities"."type" = '${isEntityExists.entityType}'
      AND "FavoriteListsEntities"."listId" = "FavoriteLists"."id")
    `),
    'isExist',
  ];

  const photosAttr = [
    literal(`
      (SELECT
        (CASE "type"
          WHEN 'events'
          THEN (
            SELECT "photoUrl"
            FROM "Events" "e"
            INNER JOIN "EventsPhoto" "eph"
            ON "eph"."eventId" = "e"."id"
            WHERE "e"."id" = "FavoriteListsEntities"."entityId"
            ORDER BY "eph"."index"
            LIMIT 1
          )
          WHEN 'openings'
          THEN (
            SELECT "photoUrl"
            FROM "Openings" "o"
            INNER JOIN "OpeningsPhoto" "oph"
            ON "oph"."openingId" = "o"."id"
            WHERE "o"."id" = "FavoriteListsEntities"."entityId"
            ORDER BY "oph"."index"
            LIMIT 1
          )
          WHEN 'businesses'
          THEN (
            SELECT "photoUrl"
            FROM "User" "u"
            INNER JOIN "BusinessPhoto" "bph"
            ON "bph"."businessId" = "u"."internalId"
            WHERE "u"."id" = "FavoriteListsEntities"."entityId"
            ORDER BY "bph"."index"
            LIMIT 1
          )
        END
      ) AS "mainPhoto"
      FROM "FavoriteListsEntities"
      WHERE "FavoriteListsEntities"."listId" = "FavoriteLists"."id"
      ORDER BY "FavoriteListsEntities"."createdAt" DESC
      LIMIT 1)
    `),
    'cover',
  ];

  const attributes = [
    'id',
    'name',
    photosAttr,
    isEntityExistsAttr,
  ].filter(Boolean) as FindOptionsAttributesArray;

  return FavoriteLists.findAll({
    attributes,
    group: [
      'id',
    ],
    order: [
      ['createdAt', 'DESC'],
    ],
    where: { foodEnthusiastId },
  });
};

export const getFavoriteListsNames = () =>
  FavoriteLists.findAll({
    where: {},
    attributes: ['id', 'name'],
  })
  .then((lists) => lists.map(prop('dataValues')));

export const isUserListOwner = (id: number, foodEnthusiastId: number) =>
  FavoriteLists.count({
    where: { id, foodEnthusiastId },
  })
  .then(Boolean);

interface GetFavoriteListByIdSelection {
  entityId: number;
  type: string;
}

const box = (range: any) => {
  const {
    leftBottom,
    rightTop,
  } = range;

  return `box '((${leftBottom.lat}, ${leftBottom.lng}), (${rightTop.lat}, ${rightTop.lng}))'`;
};

const coordsBox = (coords: any) => {
  if (!coords) {
    return '';
  }

  const {
    leftBottom,
    rightTop,
  } = coords;

  if (leftBottom.lng > rightTop.lng) {
    const range1 = {
      leftBottom,
      rightTop: {
        ...rightTop,
        lng: 180,
      },
    };

    const range2 = {
      leftBottom: {
        ...leftBottom,
        lng: -180,
      },
      rightTop,
    };

    return `
      string_to_point(("T"."entityData"->'address'->'geoPosition'::text)::varchar) <@ ${box(range1)}
      OR <@ string_to_point(("T"."entityData"->'address'->'geoPosition'::text)::varchar) ${box(range2)}
    `;
  }

  return `string_to_point(("T"."entityData"->'address'->'geoPosition'::text)::varchar) <@ ${box(coords)}`;
};

export const getFavoriteListById = async (
  listId: number,
  orderingMethod: string,
  limit: number,
  coords: any,
  pagination?: GetFavoriteListByIdSelection,
  geoPositon?: any,
) => {
  const orderingMethods = {
    recent: 'ORDER BY "FavoriteListsEntities"."createdAt" DESC',
    name: 'ORDER BY "FavoriteListsEntities"."entityData"->>\'name\'::text ASC',
    suburb: 'ORDER BY "FavoriteListsEntities"."entityData"->\'address\'->>\'locality\'::varchar ASC',
    rating: 'ORDER BY "FavoriteListsEntities"."entityData"->>\'overallRating\' DESC',
    // tslint:disable-next-line max-line-length
    distance: `ORDER BY length_by_two_points(string_to_point(("FavoriteListsEntities"."entityData"->\'address\'->\'geoPosition\'::text)::VARCHAR), point(${geoPositon.lat},${geoPositon.lng}))`,
  };

  const rows = await sequelize.query(`
  WITH "T" AS (
    SELECT
      row_number() OVER () AS "row_number",
      "rows".*
    FROM (
    SELECT "FavoriteListsEntities".*
    FROM (SELECT "entityId", "type", "note", "createdAt",
       (CASE "type"
         WHEN 'events'
         THEN (
           SELECT row_to_json("r")
           FROM (
             SELECT
               "e"."eventName" AS "name",
               0 AS "overallRating",
               get_address_as_json("e"."address") AS "address",
               array_to_json(
                 ARRAY(
                   SELECT row_to_json("p")
                   FROM (
                     SELECT
                       "eventPhoto"."id" AS "id",
                       "eventPhoto"."photoUrl" AS "url",
                       "eventPhoto"."index" AS "index"
                     FROM "Events" AS "events"
                     INNER JOIN "EventsPhoto" AS "eventPhoto"
                     ON "eventPhoto"."eventId" = "events"."id"
                     WHERE "events"."id" = "FavoriteListsEntities"."entityId"
                   ) as "p"
                 )
               ) AS "photos"
             FROM "Events" "e"
             WHERE "e"."id" = "FavoriteListsEntities"."entityId"
           ) "r"
         )
         WHEN 'openings'
         THEN (
           SELECT row_to_json("r")
           FROM (
             SELECT
               "o"."openingName" AS "name",
               0 AS "overallRating",
               get_address_as_json("o"."address") AS "address",
               array_to_json(
               ARRAY(
                 SELECT row_to_json("p")
                 FROM (
                   SELECT
                     "openingPhoto"."id" AS "id",
                     "openingPhoto"."photoUrl" AS "url",
                     "openingPhoto"."index" AS "index"
                   FROM "Openings" AS "opening"
                   INNER JOIN "OpeningsPhoto" AS "openingPhoto"
                   ON "openingPhoto"."openingId" = "opening"."id"
                   WHERE "opening"."id" = "FavoriteListsEntities"."entityId"
                 ) as "p"
               )
             ) AS "photos"
             FROM "Openings" "o"
             WHERE "o"."id" = "FavoriteListsEntities"."entityId"
           ) "r"
         )
         WHEN 'businesses'
         THEN (
           SELECT row_to_json("r")
           FROM (
             SELECT
               "b"."businessName" AS "name",
               coalesce("b"."currentOverallRating", 0) AS "overallRating",
               "b"."currentCountOfReviews" AS "reviewsCount",
               get_business_type( "b"."businessType") AS "businessType",
               get_address_as_json("b"."address") AS "address",
               -- Photos selection
               array_to_json(
                 ARRAY(
                   SELECT row_to_json("p")
                   FROM (
                     SELECT
                       "businessPhoto"."id" AS "id",
                       "businessPhoto"."photoUrl" AS "url",
                       "businessPhoto"."index" AS "index"
                     FROM "User" AS "user"
                     INNER JOIN "BusinessPhoto" AS "businessPhoto"
                     ON "businessPhoto"."businessId" = "user"."internalId"
                     WHERE "user"."id" = "FavoriteListsEntities"."entityId"
                     ORDER BY "businessPhoto"."index"
                   ) as "p"
                 )
               ) AS "photos"
             FROM "User" "u"
             LEFT JOIN "Business" "b" ON "b"."id" = "u"."internalId"
             WHERE "u"."id" = "FavoriteListsEntities"."entityId"
           ) "r"
         )
       END)
       AS "entityData" FROM "FavoriteListsEntities" AS "FavoriteListsEntities"
       WHERE "FavoriteListsEntities"."listId" = ${listId}
     ) AS "FavoriteListsEntities"
     ${prop(orderingMethod, orderingMethods)}
    ) "rows"
  )
  SELECT
      "T"."entityId",
      "T"."type",
      "T"."note",
      "T"."createdAt",
      "T"."entityData"
  FROM "T"
  ${
    coords
      ? `WHERE ${coordsBox(coords)}`
      : ''
  }
  ${
    pagination
      ? `
      OFFSET (
        SELECT "row_number" FROM "T" WHERE "T"."entityId" = ${pagination.entityId} AND "T"."type" = '${pagination.type}'
      ) - 1
      `
      : ''
  }
  LIMIT ${limit + 1};`, {
    type: QueryTypes.SELECT,
  }).map((listItem: any) => {
    const entityData = parseGeoPositionBusiness(listItem.entityData);

    return {
      ...listItem,
      entityData,
    };
  });

  const nextEntityData = rows[limit];
  const nextEntity = nextEntityData
    ? pick(['entityId', 'type'], nextEntityData)
    : null;

  return {
    nextEntity,
    rows: rows.slice(0, limit),
  };
};
