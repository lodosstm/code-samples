const supertest = require('supertest');
const { expect } = require('chai');
const {
  THIS_TITLE_NAME_ALREADY_EXIST,
  TITLE_NOT_EXIST,
} = require('../../../lib/errors');
const booter = require('../../../lib/booter');
const express = require('express');
const {
  tests: {
    getBody,
    getData,
    getToken,
  },
} = require('../../../lib/tools');

let app;

describe('Title', () => {
  const adminCredentials = {
    email: 'test@admin.com',
    password: 'password',
  };
  let authorization;

  before(async () => {
    app = supertest(await booter(express()));
  });

  before(async () => {
    authorization = await app.post('/api/signin')
      .send(adminCredentials)
      .expect(200)
      .then(getToken);
  });

  describe('Adding title', () => {
    let test;
    const titleName = 'Designer';

    before(async () => {
      test = await app.post('/api/titles')
        .set('authorization', authorization)
        .send({ name: titleName })
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "name" property', () =>
      expect(test)
        .to.have.property('name')
        .that.to.be.a('string'));
  });

  describe('Adding a title with the same name', () => {
    let test;
    const titleName = 'Designer';
    const error = THIS_TITLE_NAME_ALREADY_EXIST();

    before(async () => {
      test = await app.post('/api/titles')
        .set('authorization', authorization)
        .send({ name: titleName })
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Updating a title', () => {
    let test;
    const titleId = 1;
    const titleName = 'Web Developer';

    before(async () => {
      test = await app.put(`/api/titles/${titleId}`)
        .set('authorization', authorization)
        .send({ name: titleName })
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "success" property', () =>
      expect(test)
        .to.have.property('success')
        .to.be.true);
  });

  describe('Update title by id that not exist', () => {
    let test;
    const titleId = 100500;
    const titleName = 'IOS Developer';
    const error = TITLE_NOT_EXIST();

    before(async () => {
      test = await app.put(`/api/titles/${titleId}`)
        .set('authorization', authorization)
        .send({ name: titleName })
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Adding new title and updating a title with the exist name', () => {
    let test;
    const titleName = 'Mobile Developer';
    const titleId = 1;
    const error = THIS_TITLE_NAME_ALREADY_EXIST();

    before(async () => {
      await app.post('/api/titles')
        .set('authorization', authorization)
        .send({ name: titleName })
        .expect(200);

      test = await app.put(`/api/titles/${titleId}`)
        .set('authorization', authorization)
        .send({ name: titleName })
        .expect(error.status)
        .then(getBody);

      return test;
    });

    it('valid error', () =>
      expect(test)
        .to.have.property('code')
        .that.equals(error.code));
  });

  describe('Get titles', () => {
    let test;

    before(async () => {
      test = await app.get('/api/titles')
        .set('authorization', authorization)
        .expect(200)
        .then(getBody);

      return test;
    });

    it('have "data" property', () =>
      expect(test)
        .to.have.property('data')
        .that.to.be.an('array'));

    it('every element of the array have "id" property', () =>
      test.data
        .every(i => expect(i).to.have.property('id')
          .that.to.be.a('number')));

    it('every element of the array have "name" property', () =>
      test.data
        .every(i => expect(i).to.have.property('name')
          .that.to.be.a('string')));
  });

  describe('Get title by id', () => {
    let test;
    const titleId = 1;

    before(async () => {
      test = await app.get(`/api/titles/${titleId}`)
        .set('authorization', authorization)
        .expect(200)
        .then(getData);

      return test;
    });

    it('have "name" property', () =>
      expect(test)
        .to.have.property('name')
        .that.to.be.a('string'));
  });

  describe('Get title by id that not exist', () => {
    let test;
    const titleId = 100500;
    const error = TITLE_NOT_EXIST();

    before(async () => {
      test = await app.get(`/api/titles/${titleId}`)
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

  describe('Delete title', () => {
    let test;
    const titleId = 1;

    before(async () => {
      test = await app.delete(`/api/titles/${titleId}`)
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
});
