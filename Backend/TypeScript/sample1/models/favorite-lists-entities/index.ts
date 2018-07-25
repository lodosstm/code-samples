import {
  scheme as FavoriteListsEntities,
} from './scheme';
import sequelize from '../../../common/dbs/sequelize';
import FavoriteListsEntitiesRecord from './interfaces';

export const addPickedEntity = (listId: number, entityId: number, type: string) =>
  FavoriteListsEntities.create({ listId, entityId, type } as FavoriteListsEntitiesRecord);

export const removePickedEntity = (listId: number, entityId: number, type: string) =>
  FavoriteListsEntities.destroy({ where: { listId, entityId, type } });

export const removeAllPickedEntities = (listId: number) =>
  FavoriteListsEntities.destroy({ where: { listId } });

export const updateEntityNote = (listId: number, entityId: number, type: number, note: string) =>
  FavoriteListsEntities.update({ note } as FavoriteListsEntitiesRecord, { where: { listId, entityId, type } });

export const getEntityNote = (listId: number, entityId: number, type: number) =>
  FavoriteListsEntities.findOne({ where: { listId, entityId, type } });

export const countPickedEntities = async (listId: number) => {
  const totalPickedEntities = await FavoriteListsEntities.count({
    where: {
      listId,
    },
  });

  return totalPickedEntities;
};

export const getPickedEntities = async (listId: number, count: number, offset: number) => {
  const pickedEntities = await sequelize.query(`
    SELECT "type", "note", "FavoriteListsEntities"."createdAt", "FavoriteListsEntities"."updatedAt",

    (CASE "type"
      WHEN 'events'
      THEN (
        SELECT row_to_json("e")
        FROM (
          SELECT
            "event"."id",
            "event"."eventName" AS "name",
            array_to_json(
              array(
                SELECT row_to_json("r")
                FROM (
                  SELECT
                    "EventsPhoto"."id",
                    "EventsPhoto"."index",
                    "EventsPhoto"."photoUrl" AS "url"
                  FROM "EventsPhoto"
                  WHERE "EventsPhoto"."eventId" = "event"."id"
                ) "r"
              )
            ) as "photos",
            get_address_as_json("event"."address") as "address"
          FROM "Events" "event"
          WHERE "event"."id" = "FavoriteListsEntities"."entityId"
        ) as "e"
      )
      WHEN 'openings'
      THEN (
        SELECT row_to_json("e")
        FROM (
          SELECT
            "opening"."id",
            "opening"."openingName" AS "name",
            array_to_json(
              array(
                SELECT row_to_json("r")
                FROM (
                  SELECT
                    "OpeningsPhoto"."id",
                    "OpeningsPhoto"."index",
                    "OpeningsPhoto"."photoUrl" AS "url"
                  FROM "OpeningsPhoto"
                  WHERE "OpeningsPhoto"."openingId" = "opening"."id"
                ) "r"
              )
            ) as "photos",
            get_address_as_json("opening"."address") as "address"
          FROM "Openings" "opening"
          WHERE "opening"."id" = "FavoriteListsEntities"."entityId"
        ) as "e"
      )
      WHEN 'businesses'
      THEN (
        SELECT row_to_json("e")
        FROM (
          SELECT
            "user"."id" AS "id",
            "business"."businessName" AS "name",
            "business"."currentOverallRating" AS "overallRating",
            "business"."currentCountOfReviews" AS "countOfReviews",
            json_build_object(
              'id', "types"."id",
              'name', "types"."name"
            ) AS "businessType",
            array_to_json(
              array(
                SELECT row_to_json("r")
                FROM (
                  SELECT
                    "BusinessPhoto"."id",
                    "BusinessPhoto"."index",
                    "BusinessPhoto"."photoUrl" AS "url"
                  FROM "BusinessPhoto"
                  WHERE "BusinessPhoto"."businessId" = "business"."id"
                ) "r"
              )
            ) as "photos",
            get_address_as_json("business"."address") as "address"
          FROM "Business" "business"
          LEFT JOIN "BusinessTypes" as "types" ON "business"."businessType" = "types"."id"
          LEFT JOIN "User" "user" ON "user"."internalId" = "business"."id"
          WHERE "user"."id" = "FavoriteListsEntities"."entityId"
        ) as "e"
      )
    END) AS "entityData"

    FROM "FavoriteListsEntities"
    WHERE "FavoriteListsEntities"."listId" = ${listId}

    LIMIT ${count}
    OFFSET ${offset}
  `, {
      type: sequelize.QueryTypes.SELECT,
    });

  return pickedEntities;
};
