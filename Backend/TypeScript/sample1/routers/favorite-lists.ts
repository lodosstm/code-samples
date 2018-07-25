import * as joi from 'joi';
import { AppRouter } from '../../common/router';
import {
  createList,
  getListDetailsById,
  getLists,
  updateList,
  deleteList,
  getFavoriteList,
} from '../controllers/favorite-lists';
import checkIdInRoutePath from '../middlewares/id-in-route-path';
import Roles from '../../common/user-roles';

const coordinate = joi.object().keys({
  lat: joi.number().min(-90).max(90).required(),
  lng: joi.number().min(-180).max(180).required(),
});

const { FOOD_ENTHUSIAST } = Roles;

export const favoriteLists: AppRouter[] = [
  {
/**
 * @api {POST} /api/favorite_lists CreateFavoriteList
 * @apiName CreateFavoriteList
 * @apiVersion 0.0.1
 * @apiGroup FavoriteLists
 * @apiDescription This api create new Favorite list
 *
 * @apiHeader {String} accessToken Users unique access token
 *
 * @apiParam {String} listName
 * New favorite list name
 *
 * @apiSuccessExample {json} Success-Response:
 *  HTTP/1.1 200 OK
 *  {
 *    "data":
 *      {
 *        "id": 1,
 *        "foodEnthusiastId": 1,
 *        "name": "My super list",
 *        "listImageUrl": null,
 *        "createdAt": "2017-10-02T10:48:32.093Z"
 *      }
 *  }
 */
    path: '/favorite_lists',
    method: 'post',
    controller: createList,
    validator: {
      listName: joi.string().max(128),
    },
    allowAccess: [FOOD_ENTHUSIAST],
  },
  {
/**
 * @api {GET} /api/favorite_lists GetFavoriteLists
 * @apiName GetFavoriteLists
 * @apiVersion 0.0.1
 * @apiGroup FavoriteLists
 * @apiDescription This api get all user's Favorite lists
 *
 * @apiHeader {String} accessToken Users unique access token
 *
 * @apiSuccessExample {json} Success-Response:
 *  HTTP/1.1 200 OK
 *  {
 *    "data": [
 *      {
 *        "id": 1,
 *        "name": "My super list",
 *        "mainPhoto": "https://image.s3-ap-southeast-2.amazonaws.com/g59bMtn2mA56qhW.jpg",
 *      },
 *      {
 *        "id": 2,
 *        "name": "My super list clone",
 *        "mainPhoto": "https://image.s3-ap-southeast-2.amazonaws.com/fdsfg4sdmA56qhW.jpg",
 *      },
 *    ]
 *  }
 */
    path: '/favorite_lists',
    method: 'get',
    controller: getLists,
    validator: {
      isEntityExists: joi.object().keys({
        entityId: joi.number().integer().positive().required(),
        entityType: joi.string().valid(['businesses', 'articles', 'events', 'openings']).required(),
      }),
    },
    allowAccess: [FOOD_ENTHUSIAST],
  },
  {
/**
 * @api {GET} /api/favorite_lists/:id/details GetFavoriteListDetailsById
 * @apiName GetFavoriteListDetailsById
 * @apiVersion 0.0.1
 * @apiGroup FavoriteLists
 * @apiDescription This api get user's Favorite list by id
 *
 * @apiHeader {String} accessToken Users unique access token
 *
 * @apiSuccessExample {json} Success-Response:
 *  HTTP/1.1 200 OK
 *  {
 *    "data":
 *      {
 *        "id": 1,
 *        "name": "My super list"
 *      }
 *  }
 */
    path: '/favorite_lists/:id/details',
    method: 'get',
    controller: getListDetailsById,
    validator: {},
    middlewares: [checkIdInRoutePath],
    allowAccess: [FOOD_ENTHUSIAST],
  },
  {
/**
 * @api {PUT} /api/favorite_lists/:id UpdateFavoriteList
 * @apiName UpdateFavoriteList
 * @apiVersion 0.0.1
 * @apiGroup FavoriteLists
 * @apiDescription This api update Favorite list
 *
 * @apiHeader {String} accessToken Users unique access token
 *
 * @apiParam {String} listName
 * New favorite list name
 *
 * @apiSuccessExample {json} Success-Response:
 *  HTTP/1.1 200 OK
 *  {
 *    "data":
 *      {
 *        "id": 1,
 *        "foodEnthusiastId": 1,
 *        "name": "My super list updated",
 *        "listImageUrl": "https://image.s3-ap-southeast-2.amazonaws.com/g59bMtn2mA56qhW.jpg",
 *        "createdAt": "2017-10-02T10:48:32.093Z"
 *      }
 *  }
 */
    path: '/favorite_lists/:id',
    method: 'put',
    controller: updateList,
    validator: {
      listName: joi.string().max(128),
    },
    middlewares: [checkIdInRoutePath],
    allowAccess: [FOOD_ENTHUSIAST],
  },
  {
/**
 * @api {DELETE} /api/favorite_lists/:id DeleteFavoriteListById
 * @apiName DeleteFavoriteListsById
 * @apiVersion 0.0.1
 * @apiGroup FavoriteLists
 * @apiDescription This api delete user's Favorite list by id
 *
 * @apiHeader {String} accessToken Users unique access token
 *
 * @apiSuccessExample {json} Success-Response:
 *  HTTP/1.1 200 OK
 *  {
 *    "data":
 *      {
 *        "success": true
 *      }
 *  }
 */
    path: '/favorite_lists/:id',
    method: 'delete',
    controller: deleteList,
    validator: {},
    middlewares: [checkIdInRoutePath],
    allowAccess: [FOOD_ENTHUSIAST],
  },
  {
/**
 * @api {GET} /api/favorite_lists/:id GetFavoriteListItems
 * @apiName GetFavoriteListItems
 * @apiVersion 0.0.1
 * @apiGroup FavoriteLists
 * @apiDescription This api returns list items
 *
 * @apiHeader {String} accessToken Users unique access token
 * @apiParam {String="recent", "name", "suburb", "rating", "distance"} [order="name"] ordering method
 * @apiParam {Object} [geoPosition] User geo posistion. Required if order equals "distance"
 * @apiParam {Number} geoPosition.lat latitude
 * @apiParam {Number} geoPosition.lng longitude
 * @apiParam {Object} [pagination] "entities pagination"
 * @apiParam {Number} pagination.entityId Entitiy id
 * @apiParam {Number} pagination.type Entitiy type
 * @apiParam {Number} pagination.limit limit
 */
    path: '/favorite_lists/:id',
    method: 'get',
    controller: getFavoriteList,
    validator: {
      order: joi.string()
        .default('name')
        .allow(['recent', 'name', 'suburb', 'rating', 'distance']),
      geoPosition: coordinate.when('order', {
        is: 'distance',
        then: joi.required(),
      }).default({}),
      firstEntity: joi.object().keys({
        entityId: joi.number().positive().integer().required(),
        type: joi.string().allow(['businesses', 'events', 'openings']).required(),
      }),
      limit: joi.number().positive().integer().required().min(1),
      inRectangle: {
        leftBottom: coordinate.required(),
        rightTop: coordinate.required(),
      },
    },
    middlewares: [checkIdInRoutePath],
    allowAccess: [FOOD_ENTHUSIAST],
  },
];
