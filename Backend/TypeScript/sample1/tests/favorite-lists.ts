import 'mocha';
import * as supertest from 'supertest';
import * as chai from 'chai';
import { expect } from 'chai';
import {
  prop,
  map,
  path,
} from 'ramda';
import * as chaiAsPromised from 'chai-as-promised';
import {
  regFoodEnthusiastUser,
  authUser,
  regAndAuthBusiness,
} from '../tools/user';
import server from '../../server';
import { getBody, getData } from '../tools/request';
import AccessDenied from '../errors/access-denied';
import FavoriteListIsNotExist from '../errors/favorite-lists/favorite-list-is-not-exist';
import FavoriteListNameAlreadyExist from '../errors/favorite-lists/favorite-list-name-already-exist';

chai.use(chaiAsPromised);
const app = supertest(server);

describe('Favorite Lists', () => {
  const headers: any = {
    'Content-Type': 'application/json',
  };
  const listName = 'My super list';
  let favoriteListId: number;

  before(async () => (headers.accessToken = await authUser(await regFoodEnthusiastUser())));

  describe('Create Favorite list', () => {
    let test: Promise<any>;

    before(() =>
      (test = app.post('/api/favorite_lists')
        .set(headers)
        .send({listName})
        .expect(200)
        .then(getData)
        .then((result: any) => {
          favoriteListId = prop('id', result);

          return result;
        })));

    it('have "id" property', () =>
      expect(test)
        .to.eventually.have.property('id')
        .that.to.be.a('number'));

    it('have "foodEnthusiastId" property', () =>
      expect(test)
        .to.eventually.have.property('foodEnthusiastId')
        .that.to.be.a('number'));

    it('have "name" property', () =>
      expect(test)
        .to.eventually.have.property('name')
        .that.to.be.equals(listName));
  });

  describe('Get Favorite lists', () => {
    let test: Promise<any>;

    before(() =>
      (test = app.get('/api/favorite_lists')
        .set(headers)
        .expect(200)
        .then(getBody)));

    it('have "data" property', () =>
      expect(test)
      .to.eventually.have.deep.property('data')
      .that.to.be.an('array'));

    it('have "id" property', () =>
      expect(test)
      .to.eventually.have.deep.property('data[0].id')
      .that.to.be.a('number'));

    it('have "name" property', () =>
      expect(test)
      .to.eventually.have.deep.property('data[0].name')
      .that.to.be.a('string'));

    it('not have "isExist" property', () =>
      expect(test)
      .to.eventually.not.have.deep.property('data[0].isExist')
      .that.to.be.a('boolean'));

    it('have "photos" property', () =>
      expect(test)
        .to.eventually.have.deep.property('data[0].cover'));
  });

  describe('Get Favorite lists with isEntityExists', () => {
    let test: Promise<any>;

    before(() =>
      (test = app.get('/api/favorite_lists')
        .query({
          isEntityExists: {
            entityId: 1,
            entityType: 'events',
          }})
        .set(headers)
        .expect(200)
        .then(getBody)));

    it('have "data" property', () =>
      expect(test)
      .to.eventually.have.deep.property('data')
      .that.to.be.an('array'));

    it('have "id" property', () =>
      expect(test)
      .to.eventually.have.deep.property('data[0].id')
      .that.to.be.a('number'));

    it('have "name" property', () =>
      expect(test)
      .to.eventually.have.deep.property('data[0].name')
      .that.to.be.a('string'));

    it('have "isExist" property', () =>
      expect(test)
        .to.eventually.have.deep.property('data[0].isExist')
        .that.to.be.a('boolean'));

    it('have "photos" property', () =>
      expect(test)
        .to.eventually.have.deep.property('data[0].cover'));
  });

  describe('Get Favorite list by id', () => {
    let test: Promise<any>;

    before(() =>
      (test = app.get(`/api/favorite_lists/${favoriteListId}/details`)
        .set(headers)
        .expect(200)
        .then(getData)));

    it('have "id" property', () =>
      expect(test)
        .to.eventually.have.property('id')
        .that.to.be.a('number'));

    it('have "name" property', () =>
      expect(test)
        .to.eventually.have.property('name')
        .that.to.be.equals(listName));
  });

  describe('Update name of Favorite list to an existing one', () => {
    let test: Promise<any>;
    const newListName = 'My super list';
    const error = new FavoriteListNameAlreadyExist();

    before(() =>
      (test = app.put(`/api/favorite_lists/${favoriteListId}`)
        .set(headers)
        .send({listName: newListName})
        .expect(error.status)
        .then(getBody)));

    it('valid error', () =>
      expect(test)
        .to.eventually.have.property('code')
        .that.to.be.equals(error.code));
  });

  describe('Update name of Favorite list', () => {
    let test: Promise<any>;
    const newListName = 'My super edited list';

    before(() =>
      (test = app.put(`/api/favorite_lists/${favoriteListId}`)
        .set(headers)
        .send({listName: newListName})
        .expect(200)
        .then(getData)));

    it('have "name" property', () =>
      expect(test)
        .to.eventually.have.property('name')
        .that.to.be.equals(newListName));
  });

  describe('Access to list of the other user', () => {
    let test: Promise<any>;
    const customHeaders = {
      accessToken: '',
    };
    const error = new AccessDenied();

    before(async () => (customHeaders.accessToken = await authUser(await regFoodEnthusiastUser())));

    before(() =>
      (test = app.get(`/api/favorite_lists/${favoriteListId}/details`)
        .set(customHeaders)
        .expect(error.status)
        .then(getBody)));

    it('valid error', () =>
      expect(test)
        .to.eventually.have.property('code')
        .that.to.be.equals(error.code));
  });

  describe('Delete Favorite list', () => {
    let test: Promise<any>;

    before(() =>
      (test = app.delete(`/api/favorite_lists/${favoriteListId}`)
        .set(headers)
        .expect(200)
        .then(getData)));

    it('success', () =>
      expect(test)
        .to.eventually.have.property('success')
        .that.to.be.true);
  });

  describe('Access to nonexistent favorite list', () => {
    let test: Promise<any>;
    const error = new FavoriteListIsNotExist();
    const nonexistentId = 99999999999;

    before(() =>
      (test = app.get(`/api/favorite_lists/${nonexistentId}/details`)
        .set(headers)
        .expect(error.status)
        .then(getBody)));

    it('valid error', () =>
      expect(test)
        .to.eventually.have.property('code')
        .that.to.be.equals(error.code));
  });
});
