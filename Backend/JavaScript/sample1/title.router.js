const {
  POST,
  PUT,
  GET,
  DELETE,
} = require('express-object-router/methods');
const joi = require('joi');
const mainController = require('./title.controller');
const { ADMIN } = require('../../../lib/user-roles');

const checkIdRules = joi.number().integer().positive().required()
  .description('title Id');

module.exports = [
  {
  /**
 * @api {POST} /api/titles addTitles
 * @apiName AddTitles
 * @apiVersion 0.0.1
 * @apiGroup Titles
 * @apiDescription This api adding title
 */
    method: POST,
    path: '/titles',
    controller: mainController.addTitle,
    validation: {
      body: {
        name: joi.string().required().description('title name'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {PUT} /api/titles/:id updateTitles
 * @apiName UpdateTitles
 * @apiVersion 0.0.1
 * @apiGroup Titles
 * @apiDescription This api updating title
 */
    method: PUT,
    path: '/titles/:id',
    controller: mainController.updateTitle,
    validation: {
      params: {
        id: checkIdRules,
      },
      body: {
        name: joi.string().required().description('title name'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {GET} /api/titles getAllTitles
 * @apiName GetAllTitles
 * @apiVersion 0.0.1
 * @apiGroup Titles
 * @apiDescription This api getting titles
 */
    method: GET,
    path: '/titles',
    controller: mainController.getTitles,
    validation: {},
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {GET} /api/titles/:id getTitles
 * @apiName GetTitles
 * @apiVersion 0.0.1
 * @apiGroup Titles
 * @apiDescription This api getting title by id
 */
    method: GET,
    path: '/titles/:id',
    controller: mainController.getTitle,
    validation: {
      params: {
        id: checkIdRules,
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {DELETE} /api/titles/:id deleteTitles
 * @apiName DeleteTitles
 * @apiVersion 0.0.1
 * @apiGroup Titles
 * @apiDescription This api deletion title
 */
    method: DELETE,
    path: '/titles/:id',
    controller: mainController.deleteTitle,
    validation: {
      params: {
        id: checkIdRules,
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
];
