const Title = require('./title.scheme');

const UNIQUE_CONSTRAINT_TITLES_NAME = 'Titles_name_key';

const createTitle = name =>
  Title.create({
    name,
  });

const getAllTitles = () =>
  Title.findAll({
    attributes: ['id', 'name'],
  });

const getTitleById = id =>
  Title.findById(id, {
    attributes: ['id', 'name'],
  });

const updateTitle = (id, name) =>
  Title.update({
    name,
  }, {
    where: { id },
  });

const deleteTitleById = id =>
  Title.destroy({
    where: {
      id,
    },
  });

module.exports = {
  createTitle,
  getTitleById,
  getAllTitles,
  updateTitle,
  deleteTitleById,
  UNIQUE_CONSTRAINT_TITLES_NAME,
};
