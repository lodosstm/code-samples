const {
  POST,
  PUT,
  GET,
  DELETE,
} = require('express-object-router/methods');
const joi = require('joi');
const mainController = require('./project.controller');
const { ADMIN } = require('../../../lib/user-roles');

const checkIdRules = joi.number().integer().positive().required();

module.exports = [
  {
  /**
 * @api {POST} /api/projects addProject
 * @apiName AddProject
 * @apiVersion 0.0.1
 * @apiGroup Projects
 * @apiDescription This api adding project
 */
    method: POST,
    path: '/projects',
    controller: mainController.addProject,
    validation: {
      body: {
        title: joi.string().required().description('project title'),
        managerId: checkIdRules.description('manager id'),
        estimatedTime: joi.number().positive().required().description('time that sales'),
        isDirectContract: joi.boolean().description('direct contract flag'),
        startDate: joi.date().description('start date of project'),
        endDate: joi.date().description('end date of project'),
        status: joi.string().valid('opened', 'closed').required().description('project status'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {PUT} /api/projects/:id updateProject
 * @apiName UpdateProject
 * @apiVersion 0.0.1
 * @apiGroup Projects
 * @apiDescription This api updating project
 */
    method: PUT,
    path: '/projects/:id',
    controller: mainController.updateProject,
    validation: {
      params: {
        id: checkIdRules.description('project id'),
      },
      body: {
        title: joi.string().required().description('project title'),
        managerId: checkIdRules.description('manager id'),
        estimatedTime: joi.number().positive().required().description('time that sales'),
        isDirectContract: joi.boolean().description('direct contract flag'),
        startDate: joi.date().description('start date of project'),
        endDate: joi.date().description('end date of project'),
        status: joi.string().valid('opened', 'closed').required().description('project status'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
    /**
   * @api {PUT} /api/projects/:id/closing closingProject
   * @apiName СlosingProject
   * @apiVersion 0.0.1
   * @apiGroup Projects
   * @apiDescription This api closing project
   */
    method: PUT,
    path: '/projects/:id/closing',
    controller: mainController.closingProject,
    validation: {
      params: {
        id: checkIdRules.description('project id'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {GET} /api/projects getAllProjects
 * @apiName GetAllProjects
 * @apiVersion 0.0.1
 * @apiGroup Projects
 * @apiDescription This api getting project
 */
    method: GET,
    path: '/projects',
    controller: mainController.getProjects,
    validation: {
      query: {
        limit: joi
          .number()
          .integer()
          .positive()
          .max(25)
          .default(25)
          .description('output of so many users'),
        offset: joi
          .number()
          .integer()
          .min(0)
          .default(0)
          .description('shift of received data'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {GET} /api/projects/:id getProject
 * @apiName GetProject
 * @apiVersion 0.0.1
 * @apiGroup Projects
 * @apiDescription This api getting project by id
 */
    method: GET,
    path: '/projects/:id',
    controller: mainController.getProject,
    validation: {
      params: {
        id: checkIdRules.description('project id'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {GET} /api/projects/:id/team getTeam
 * @apiName GetTeam
 * @apiVersion 0.0.1
 * @apiGroup Projects
 * @apiDescription This api getting team by project id
 */
    method: GET,
    path: '/projects/:id/team',
    controller: mainController.getTeam,
    validation: {
      params: {
        id: checkIdRules.description('project id'),
      },
      query: {
        limit: joi
          .number()
          .integer()
          .positive()
          .max(25)
          .default(25)
          .description('output of so many users'),
        offset: joi
          .number()
          .integer()
          .min(0)
          .default(0)
          .description('shift of received data'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
  {
  /**
 * @api {DELETE} /api/projects/:id deleteProject
 * @apiName DeleteProject
 * @apiVersion 0.0.1
 * @apiGroup Projects
 * @apiDescription This api deletion project
 */
    method: DELETE,
    path: '/projects/:id',
    controller: mainController.deleteProject,
    validation: {
      params: {
        id: checkIdRules.description('project id'),
      },
    },
    middlewaresProps: {
      allowAccess: [ADMIN],
    },
  },
];
