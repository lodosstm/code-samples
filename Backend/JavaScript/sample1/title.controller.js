const Title = require('./title.model');
const {
  THIS_TITLE_NAME_ALREADY_EXIST,
  TITLE_NOT_EXIST,
} = require('../../../lib/errors');

const addTitle = async ({
  reply,
  body: { name: titleName },
}) => {
  try {
    const {
      id,
      name,
    } = await Title.createTitle(titleName);

    reply({ id, name });
  } catch (err) {
    if (err.parent.constraint === Title.UNIQUE_CONSTRAINT_TITLES_NAME) {
      throw THIS_TITLE_NAME_ALREADY_EXIST();
    }

    throw err;
  }
};

const updateTitle = async ({
  reply,
  params: { id },
  body: { name },
}) => {
  const isTitleExists = Boolean(await Title.getTitleById(id));

  if (!isTitleExists) {
    throw TITLE_NOT_EXIST();
  }

  try {
    await Title.updateTitle(id, name);
  } catch (err) {
    if (err.parent.constraint === Title.UNIQUE_CONSTRAINT_TITLES_NAME) {
      throw THIS_TITLE_NAME_ALREADY_EXIST();
    }

    throw err;
  }

  reply({ success: true });
};

const getTitles = async ({
  reply,
}) => {
  const result = await Title.getAllTitles();

  reply(result);
};

const getTitle = async ({
  reply,
  params: { id },
}) => {
  const result = await Title.getTitleById(id);

  if (!result) {
    throw TITLE_NOT_EXIST();
  }

  reply(result);
};

const deleteTitle = async ({
  reply,
  params: { id },
}) => {
  await Title.deleteTitleById(id);

  reply({ success: true });
};

module.exports = {
  addTitle,
  updateTitle,
  getTitles,
  getTitle,
  deleteTitle,
};
