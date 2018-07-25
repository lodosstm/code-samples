const Project = require('./project.model');
const {
  PROJECT_WITH_THIS_NAME_ALREADY_EXIST,
  PROJECT_NOT_EXIST,
  MANAGER_NOT_EXIST,
  PROJECT_STILL_HAS_PEOPLE,
} = require('../../../lib/errors');

const addProject = async ({
  reply,
  body: {
    title: enteredTitle,
    managerId: enteredManagerId,
    estimatedTime: enteredEstimatedTime,
    isDirectContract: enteredIsDirectContract,
    status: enteredStatus,
    startDate: enteredStartDate,
    endDate: enteredEndDate,
  },
}) => {
  try {
    const {
      id,
      title,
      managerId,
      estimatedTime,
      status,
      isDirectContract,
      startDate,
      endDate,
    } = await Project.createProject(
      enteredTitle,
      enteredManagerId,
      enteredEstimatedTime,
      enteredIsDirectContract,
      enteredStatus,
      enteredStartDate,
      enteredEndDate,
    );

    reply({
      id,
      title,
      managerId,
      estimatedTime,
      isDirectContract,
      status,
      startDate,
      endDate,
    });
  } catch (err) {
    if (err.parent.constraint === Project.UNIQUE_CONSTRAINT_PROJECTS_TITLE) {
      throw PROJECT_WITH_THIS_NAME_ALREADY_EXIST();
    }

    if (err.parent.constraint === Project.FKEY_CONSTRAINT_PROJECTS_MANAGER_ID) {
      throw MANAGER_NOT_EXIST();
    }

    throw err;
  }
};

const updateProject = async ({
  reply,
  params: { id },
  body: {
    title,
    managerId,
    estimatedTime,
    isDirectContract,
    status,
    startDate,
    endDate,
  },
}) => {
  const isProjectExists = Boolean(await Project.getProjectById(id));

  if (!isProjectExists) {
    throw PROJECT_NOT_EXIST();
  }

  try {
    await Project.updateProject(
      id,
      title,
      managerId,
      estimatedTime,
      isDirectContract,
      status,
      startDate,
      endDate,
    );
  } catch (err) {
    if (err.parent.constraint === Project.UNIQUE_CONSTRAINT_PROJECTS_TITLE) {
      throw PROJECT_WITH_THIS_NAME_ALREADY_EXIST();
    }

    if (err.parent.constraint === Project.FKEY_CONSTRAINT_PROJECTS_MANAGER_ID) {
      throw MANAGER_NOT_EXIST();
    }

    throw err;
  }

  reply({ success: true });
};

const closingProject = async ({
  reply,
  params: { id },
}) => {
  const isProjectExists = Boolean(await Project.getProjectById(id));

  if (!isProjectExists) {
    throw PROJECT_NOT_EXIST();
  }

  const isPeopleOnProject = await Project.isPeopleOnProject(id);

  if (isPeopleOnProject) {
    throw PROJECT_STILL_HAS_PEOPLE();
  }

  await Project.closingProjectById(id);

  reply({ success: true });
};

const getProjects = async ({
  reply,
  query: {
    limit,
    offset,
  },
}) => {
  const result = await Project.getAllProjects(limit, offset);

  reply(result);
};

const getProject = async ({
  reply,
  params: { id },
}) => {
  const result = await Project.getProjectById(id);

  if (!result) {
    throw PROJECT_NOT_EXIST();
  }

  reply(result);
};

const getTeam = async ({
  reply,
  params: { id },
  query: {
    limit,
    offset,
  },
}) => {
  const rows = await Project.getTeamByProjectId(id, limit, offset);
  const count = await Project.getCountTeamMembersByProjectId(id);

  reply({ count, rows });
};

const deleteProject = async ({
  reply,
  params: { id },
}) => {
  await Project.deleteProjectById(id);

  reply({ success: true });
};

module.exports = {
  addProject,
  updateProject,
  closingProject,
  getProjects,
  getProject,
  getTeam,
  deleteProject,
};
