module.exports = [
  {
    name: 'PROJECT_WITH_THIS_NAME_ALREADY_EXIST',
    status: 400,
    message: 'Project with this name already exists',
  },
  {
    name: 'PROJECT_NOT_EXIST',
    status: 400,
    message: 'Project doesn\'t exist',
  },
  {
    name: 'PROJECT_NOT_OPENED',
    status: 400,
    message: 'Project doesn\'t opened',
  },
  {
    name: 'PROJECT_STILL_HAS_PEOPLE',
    status: 400,
    message: 'The project still has people with nonzero performance',
  },
];
