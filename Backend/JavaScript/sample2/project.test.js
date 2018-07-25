const supertest = require('supertest');
const { expect } = require('chai');
const booter = require('../../../lib/booter');
const express = require('express');
const randomstring = require('randomstring').generate;
const sinon = require('sinon');
const Project = require('./project.scheme');
const TimedoctorAccount = require('../timedoctor-accounts/timedoctor-accounts.model');
const User = require('../user/user.model');
const ProjectUser = require('../project-user/project-user.scheme');
const timeTools = require('../time/time.tools');
const {
  PROJECT_WITH_THIS_NAME_ALREADY_EXIST,
  PROJECT_NOT_EXIST,
  MANAGER_NOT_EXIST,
  PROJECT_STILL_HAS_PEOPLE,
} = require('../../../lib/errors');
const {
  tests: {
    getBody,
    getData,
    getToken,
  },
} = require('../../../lib/tools');

let app;

describe('Project', () => {
  const adminCredentials = {
    email: 'test@admin.com',
    password: 'password',
  };
  let authorization;
  let userId;
  let stubTimedoctor;
  let stubUpwork;

  before(async () => {
    app = supertest(await booter(express()));
  });

  before(() => {
    stubTimedoctor = sinon.stub(timeTools, 'updateTimeFromTimedoctor');
  });

  before(() => {
    stubUpwork = sinon.stub(timeTools, 'updateTimeFromUpwork');
  });

  after(() => {
    stubUpwork.restore();
    stubTimedoctor.restore();
  });

  before(async () => {
    authorization = await app.post('/api/signin')
      .send(adminCredentials)
      .expect(200)
      .then(getToken);
  });

  before(async () => {
    const { id: timedoctorAccountId } = await TimedoctorAccount.createTimedoctorAccount({
      timedoctorId: 'pro ject',
      fullName: 'pro ject',
      externalId: 'pro ject',
    });

    const { id } = await User.createUserByObjectWithParams({
      email: `${randomstring(8)}@test.test`,
      password: 'password',
      role: 'user',
      firstName: 'pro',
      lastName: 'ject',
      timedoctorAccountId,
      statusKey: 'active',
      dateIncome: Date.now(),
    });

    userId = id;
  });

  describe('Adding project', () => {
    let test;
    const projectData = {
      title: 'Inside',
      managerId: 1,
      estimatedTime: 300,
      status: 'opened',
    };

    before(async () => {
      test = await app.post('/api/projects')
        .set('authorization', authorization)
        .send(projectData)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "title" property', () =>
      expect(test)
        .to.have.property('title')
        .that.to.be.a('string'));

    it('have "managerId" property', () =>
      expect(test)
        .to.have.property('managerId')
        .that.to.be.a('number'));

    it('have "estimatedTime" property', () =>
      expect(test)
        .to.have.property('estimatedTime')
        .that.to.be.a('number'));

    it('have "status" property', () =>
      expect(test)
        .to.have.property('status')
        .that.to.be.a('string'));

    it('have "startDate" property', () =>
      expect(test)
        .to.have.property('startDate'));

    it('have "endDate" property', () =>
      expect(test)
        .to.have.property('endDate'));

    it('have "isDirectContract" property', () =>
      expect(test)
        .to.have.property('isDirectContract')
        .that.to.be.a('boolean'));
  });

  describe('Adding a project with the same name', () => {
    let test;
    const projectData = {
      title: 'Inside',
      managerId: 1,
      estimatedTime: 200,
      status: 'opened',
    };
    const error = PROJECT_WITH_THIS_NAME_ALREADY_EXIST();

    before(async () => {
      test = await app.post('/api/projects')
        .set('authorization', authorization)
        .send(projectData)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Adding a project with the nonexist managerId', () => {
    let test;
    const projectData = {
      title: 'Beforeside',
      managerId: 100500,
      estimatedTime: 200,
      status: 'opened',
    };
    const error = MANAGER_NOT_EXIST();

    before(async () => {
      test = await app.post('/api/projects')
        .set('authorization', authorization)
        .send(projectData)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Updating a project', () => {
    let test;
    const title = 'Inside';
    const projectData = {
      title: 'Outside',
      managerId: 1,
      estimatedTime: 300,
      status: 'opened',
    };

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      test = await app.put(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .send(projectData)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "success" property', () =>
      expect(test)
        .to.have.property('success')
        .to.be.true);
  });

  describe('Updating a project with the nonexist managerId', () => {
    let test;
    const title = 'Outside';
    const projectData = {
      title: 'Beforeside',
      managerId: 100500,
      estimatedTime: 200,
      status: 'opened',
    };
    const error = MANAGER_NOT_EXIST();

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      test = await app.put(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .send(projectData)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Updating project by id that not exist', () => {
    let test;
    const projectId = 100500;
    const projectData = {
      title: 'Outside',
      managerId: 1,
      estimatedTime: 300,
      status: 'opened',
    };
    const error = PROJECT_NOT_EXIST();

    before(async () => {
      test = await app.put(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .send(projectData)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Adding new project and updating a project with the exist name', () => {
    let test;
    const projectData = {
      title: 'Inside',
      managerId: 1,
      estimatedTime: 300,
      status: 'opened',
    };
    const title = 'Outside';
    const error = PROJECT_WITH_THIS_NAME_ALREADY_EXIST();

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      await app.post('/api/projects')
        .set('authorization', authorization)
        .send(projectData)
        .expect(200);

      test = await app.put(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .send(projectData)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Get projects', () => {
    let test;

    before(async () => {
      test = await app.get('/api/projects')
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "rows" property', () =>
      expect(test)
        .to.have.property('rows')
        .that.to.be.an('array'));

    it('have "count" property', () =>
      expect(test)
        .to.have.property('count')
        .that.to.be.a('number'));

    it('every element of the array have "title" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('title')
          .that.to.be.a('string')));

    it('every element of the array have "estimatedTime" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('estimatedTime')));

    it('every element of the array have "status" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('status')
          .that.to.be.a('string')));

    it('every element of the array have "startDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('startDate')));

    it('every element of the array have "endDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('endDate')));

    it('every element of the array have "isDirectContract" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('isDirectContract')
          .that.to.be.a('boolean')));

    it('every element of the array have "manager.id" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.id')
          .that.to.be.a('number')));

    it('every element of the array have "manager.firstName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.firstName')));

    it('every element of the array have "manager.lastName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.lastName')));

    it('every element of the array have "manager.surName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.surName')));
  });

  describe('Get projects with limit and offset', () => {
    let test;

    before(async () => {
      test = await app.get('/api/projects?limit=2&offset=1')
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "rows" property', () =>
      expect(test)
        .to.have.property('rows')
        .that.to.be.an('array'));

    it('have "count" property', () =>
      expect(test)
        .to.have.property('count')
        .that.to.be.a('number'));

    it('every element of the array have "title" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('title')
          .that.to.be.a('string')));

    it('every element of the array have "estimatedTime" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('estimatedTime')));

    it('every element of the array have "status" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('status')
          .that.to.be.a('string')));

    it('every element of the array have "startDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('startDate')));

    it('every element of the array have "endDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('endDate')));

    it('every element of the array have "isDirectContract" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('isDirectContract')
          .that.to.be.a('boolean')));

    it('every element of the array have "manager.id" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.id')
          .that.to.be.a('number')));

    it('every element of the array have "manager.firstName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.firstName')));

    it('every element of the array have "manager.lastName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.lastName')));

    it('every element of the array have "manager.surName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('manager.surName')));
  });

  describe('Get team', () => {
    let test;
    const title = 'Outside';

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });
      const bodyData = {
        projectId,
        userId,
      };

      await app.post('/api/projects_users')
        .set('authorization', authorization)
        .send(bodyData)
        .expect(200);

      test = await app.get(`/api/projects/${projectId}/team`)
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "rows" property', () =>
      expect(test)
        .to.have.property('rows')
        .that.to.be.an('array')
        .that.to.be.not.empty);

    it('have "count" property', () =>
      expect(test)
        .to.have.property('count')
        .that.to.be.a('number'));

    it('every element of the array have "startDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('startDate')));

    it('every element of the array have "endDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('endDate')));

    it('every element of the array have "upworkHours" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('upworkHours')));

    it('every element of the array have "timedoctorHours" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('timedoctorHours')));

    it('every element of the array have "upworkAccountId" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('upworkAccountId')));

    it('every element of the array have "user" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('user')));

    it('every element of the array have "user.id" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.id')
          .that.to.be.a('number')));

    it('every element of the array have "user.firstName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.firstName')));

    it('every element of the array have "user.lastName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.lastName')));

    it('every element of the array have "user.title" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.title')));
  });

  describe('Get team with offset and limit', () => {
    let test;
    const title = 'Outside';

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      test = await app.get(`/api/projects/${projectId}/team?limit=1&offset=0`)
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "rows" property', () =>
      expect(test)
        .to.have.property('rows')
        .that.to.be.an('array')
        .that.to.be.not.empty);

    it('have "count" property', () =>
      expect(test)
        .to.have.property('count')
        .that.to.be.a('number'));

    it('every element of the array have "startDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('startDate')));

    it('every element of the array have "endDate" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('endDate')));

    it('every element of the array have "upworkHours" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('upworkHours')));

    it('every element of the array have "timedoctorHours" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('timedoctorHours')));

    it('every element of the array have "upworkAccountId" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('upworkAccountId')));

    it('every element of the array have "user" property', () =>
      test.rows
        .every(i => expect(i).to.have.property('user')));

    it('every element of the array have "user.id" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.id')
          .that.to.be.a('number')));

    it('every element of the array have "user.firstName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.firstName')));

    it('every element of the array have "user.lastName" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.lastName')));

    it('every element of the array have "user.title" property', () =>
      test.rows
        .every(i => expect(i).to.have.nested.property('user.title')));
  });

  describe('Get project by id', () => {
    let test;
    const title = 'Outside';

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      test = await app.get(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "title" property', () =>
      expect(test)
        .to.have.property('title')
        .that.to.be.a('string'));

    it('have "estimatedTime" property', () =>
      expect(test)
        .to.have.property('estimatedTime')
        .that.to.be.a('number'));

    it('have "status" property', () =>
      expect(test)
        .to.have.property('status')
        .that.to.be.a('string'));

    it('have "startDate" property', () =>
      expect(test)
        .to.have.property('startDate'));

    it('have "endDate" property', () =>
      expect(test)
        .to.have.property('endDate'));

    it('have "isDirectContract" property', () =>
      expect(test)
        .to.have.property('isDirectContract')
        .that.to.be.a('boolean'));

    it('have "manager.id" property', () =>
      expect(test)
        .to.have.nested.property('manager.id')
        .that.to.be.a('number'));

    it('have "manager.firstName" property', () =>
      expect(test)
        .to.have.nested.property('manager.firstName'));

    it('have "manager.lastName" property', () =>
      expect(test)
        .to.have.nested.property('manager.lastName'));

    it('have "manager.surName" property', () =>
      expect(test)
        .to.have.nested.property('manager.surName'));
  });

  describe('Get project by id that not exist', () => {
    let test;
    const projectId = 100500;
    const error = PROJECT_NOT_EXIST();

    before(async () => {
      test = await app.get(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Delete project', () => {
    let test;
    const title = 'Outside';

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      test = await app.delete(`/api/projects/${projectId}`)
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "success" property', () =>
      expect(test)
        .to.have.property('success')
        .to.be.true);
  });

  describe('Close project with people that have performance', () => {
    let test;
    const title = 'Inside';
    const error = PROJECT_STILL_HAS_PEOPLE();

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      test = await app.post('/api/projects_users')
        .set('authorization', authorization)
        .send({
          userId,
          projectId,
        })
        .expect(200)
        .then(getData);

      test = await app.put(`/api/projects/${projectId}/closing`)
        .set('authorization', authorization)
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Close project', () => {
    let test;
    const title = 'Inside';

    before(async () => {
      const { id: projectId } = await Project.findOne({
        attributes: ['id'],
        where: {
          title,
        },
      });

      await ProjectUser.update({
        endDate: Date.now(),
      }, {
        where: {
          userId,
          endDate: null,
        },
      });

      await app.put(`/api/projects/${projectId}/closing`)
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      const {
        dataValues: projectData,
      } = await Project.findOne({
        where: {
          id: projectId,
        },
      });
      test = projectData;

      return test;
    });

    it('project status "closed"', () =>
      expect(test)
        .to.have.property('status')
        .that.equals('closed'));

    it('endDate is not null', () =>
      expect(test)
        .to.have.property('endDate')
        .to.be.not.null);
  });
});
