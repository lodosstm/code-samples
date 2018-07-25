const Project = require('./project.scheme');
const User = require('../user/user.scheme');
const ProjectUser = require('../project-user/project-user.scheme');
const Title = require('../title/title.scheme');
const UpworkUser = require('../upwork-users/upwork-users.scheme');
const Time = require('../time/time.scheme');
const sequelize = require('../../../lib/sequelize');

const UNIQUE_CONSTRAINT_PROJECTS_TITLE = 'Projects_title_key';
const FKEY_CONSTRAINT_PROJECTS_MANAGER_ID = 'Projects_managerId_fkey';

const createProject = (
  title,
  managerId,
  estimatedTime,
  isDirectContract,
  status,
  startDate,
  endDate,
) =>
  Project.create({
    title,
    managerId,
    estimatedTime,
    isDirectContract,
    status,
    startDate,
    endDate,
  });

const createProjectByObjectWithParams = objectWithParams =>
  Project.create(objectWithParams);

Project.belongsTo(User, {
  foreignKey: 'managerId',
  as: 'manager',
});

const getAllProjects = (limit, offset) =>
  Project.findAndCountAll({
    attributes: [
      'id',
      'title',
      'estimatedTime',
      'isDirectContract',
      'status',
      'startDate',
      'endDate',
      'createdAt',
    ],
    include: [{
      model: User,
      as: 'manager',
      attributes: [
        'id',
        'firstName',
        'lastName',
        'surName',
      ],
    }],
    limit,
    offset,
  });

const getMainDataOfOpenProjects = () =>
  Project.findAll({
    attributes: [
      'id',
      'title',
      'startDate',
    ],
    where: {
      status: 'opened',
    },
  });

const getProjectById = id =>
  Project.findById(id, {
    attributes: [
      'id',
      'title',
      'estimatedTime',
      'isDirectContract',
      'status',
      'startDate',
      'endDate',
      'createdAt',
    ],
    include: [{
      model: User,
      as: 'manager',
      attributes: [
        'id',
        'firstName',
        'lastName',
        'surName',
      ],
    }],
  });

const getProjectByTitle = title =>
  Project.findOne({
    where: {
      title,
    },
  });

ProjectUser.belongsTo(User, {
  foreignKey: 'userId',
  as: 'user',
});

User.belongsTo(Title, {
  foreignKey: 'titleId',
  as: 'title',
});

ProjectUser.belongsTo(UpworkUser, {
  foreignKey: 'userId',
  targetKey: 'userId',
});

ProjectUser.belongsTo(Time, {
  foreignKey: 'projectId',
  targetKey: 'projectId',
});

ProjectUser.belongsTo(Time, {
  foreignKey: 'userId',
  targetKey: 'userId',
});

const getTeamByProjectId = (projectId, limit, offset) =>
  ProjectUser.findAll({
    attributes: [
      'startDate',
      'endDate',
      [sequelize.fn('sum', sequelize.col('Time.upworkHours')), 'upworkHours'],
      [sequelize.fn('sum', sequelize.col('Time.timedoctorHours')), 'timedoctorHours'],
      [sequelize.col('UpworkUser.upworkAccountId'), 'upworkAccountId'],
    ],
    include: [{
      model: User,
      as: 'user',
      attributes: [
        'id',
        'firstName',
        'lastName',
      ],
      include: [{
        model: Title,
        as: 'title',
        attributes: [
          'id',
          'name',
        ],
      }],
    }, {
      model: UpworkUser,
      attributes: [],
    }, {
      model: Time,
      attributes: [],
    }],
    group: [
      'ProjectsUsers.startDate',
      'ProjectsUsers.endDate',
      'user.id',
      'user.firstName',
      'user.lastName',
      'ProjectsUsers.projectId',
      'user->title.id',
      'UpworkUser.id',
    ],
    having: {
      '$ProjectsUsers.projectId$': projectId,
      '$UpworkUser.endDate$': null,
    },
    order: [
      ['endDate', 'DESC'],
      ['startDate', 'ASC'],
    ],
    limit,
    offset,
  });

const getDataForPerformance = (startDate, endDate, id) =>
  sequelize.query(`
    SELECT 
      "Projects"."id" as "projectId",
      "isDirectContract",
      "estimatedTime",
      (SUM("Time"."upworkHours")) AS "paidTime",
      (
        SELECT
            (SUM("timedoctorHours") + SUM("upworkHours") + SUM(COALESCE("hours", 0))) AS "spentTime"
        FROM "Time"
        LEFT JOIN "ManualTime"
            ON "Time"."userId" = "ManualTime"."userId"
            AND "Time"."projectId" = "ManualTime"."projectId"
            AND "Time"."date" = "ManualTime"."date"
        WHERE "Time"."projectId" = "Projects"."id" AND "Time"."date" BETWEEN '${startDate}' AND '${endDate}'
      ),
      array_to_json(
        array(
            SELECT row_to_json("team")
            FROM (
              SELECT
                "ProjectUser"."userId",
                "Users"."workingHours",
                (
                  SELECT
                    (SUM("timedoctorHours") + SUM("upworkHours") + SUM(COALESCE("hours", 0))) AS "hoursOnAllProjects"
                  FROM "Time"
                  LEFT JOIN "ManualTime"
                    ON "Time"."userId" = "ManualTime"."userId"
                    AND "Time"."projectId" = "ManualTime"."projectId"
                    AND "Time"."date" = "ManualTime"."date"
                  WHERE "Time"."userId" = "ProjectUser"."userId" AND "Time"."date" BETWEEN '${startDate}' AND '${endDate}'
                ),
                (
                  SELECT
                    (SUM("timedoctorHours") + SUM("upworkHours") + SUM(COALESCE("hours", 0))) AS "hoursOnThisProject"
                  FROM "Time"
                  LEFT JOIN "ManualTime"
                    ON "Time"."userId" = "ManualTime"."userId"
                    AND "Time"."projectId" = "ManualTime"."projectId"
                    AND "Time"."date" = "ManualTime"."date"
                  WHERE "Time"."projectId" = "ProjectUser"."projectId" AND "Time"."userId" = "ProjectUser"."userId" AND "Time"."date" BETWEEN '${startDate}' AND '${endDate}'
                ),
                array_to_json(
                  array(
                    SELECT row_to_json("statuses")
                    FROM (
                      SELECT
                        "Status"."statusKey",
                        "Status"."startDate",
                        "Status"."endDate"
                      FROM "UserStatusLog" "Status"
                      WHERE (
                        "Status"."userId" = "ProjectUser"."userId"
                        AND ("startDate" <= '${endDate}')
                        AND ("statusKey" IN ('on_vacation', 'not_active', 'sick'))
                        AND ("endDate" IS NULL OR ("startDate" != "endDate" AND "endDate" > '${startDate}'))
                      )
                    ) AS "statuses"
                  )
                ) AS "statuses"
              FROM "ProjectsUsers" "ProjectUser"
              LEFT JOIN "Users"
              ON "ProjectUser"."userId" = "Users"."id"
              WHERE "ProjectUser"."projectId" = "Projects"."id"
            ) AS "team"
          )
        ) AS "team"
    FROM "Projects"
    LEFT JOIN "Time"
    ON "Time"."projectId" = "Projects"."id" AND "Time"."date" BETWEEN '${startDate}' AND '${endDate}'
    GROUP By "Projects"."id"
    ${id ? `HAVING "Projects"."id" = ${id}` : ''}
  `, {
    type: sequelize.QueryTypes.SELECT,
  });

const getCountTeamMembersByProjectId = projectId =>
  ProjectUser.count({
    where: {
      projectId,
    },
  });

const updateProject = (
  id,
  title,
  managerId,
  estimatedTime,
  isDirectContract,
  status,
  startDate,
  endDate,
) =>
  Project.update({
    title,
    managerId,
    estimatedTime,
    isDirectContract,
    status,
    startDate,
    endDate,
  }, {
    where: { id },
  });

const closingProjectById = id =>
  Project.update({
    endDate: Date.now(),
    status: 'closed',
  }, {
    where: {
      id,
    },
  });

const deleteProjectById = id =>
  Project.destroy({
    where: {
      id,
    },
  });

const isPeopleOnProject = async projectId =>
  Boolean(await ProjectUser.count({
    where: {
      projectId,
      isPerformance: true,
      endDate: null,
    },
    limit: 1,
  }));

module.exports = {
  createProject,
  createProjectByObjectWithParams,
  getProjectById,
  getProjectByTitle,
  getAllProjects,
  getTeamByProjectId,
  getCountTeamMembersByProjectId,
  updateProject,
  closingProjectById,
  deleteProjectById,
  isPeopleOnProject,
  getDataForPerformance,
  getMainDataOfOpenProjects,
  UNIQUE_CONSTRAINT_PROJECTS_TITLE,
  FKEY_CONSTRAINT_PROJECTS_MANAGER_ID,
};
