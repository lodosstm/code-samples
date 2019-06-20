import { Meteor } from 'meteor/meteor';
import { check } from 'meteor/check';
import { errors } from '../../constants';
import { userCheck } from '../../security';
import { Services } from '../../collections';

const {
  NOT_FOUND,
} = errors;

if (Meteor.isServer) {
  Meteor.publish('services', () => Services.find({ isActive: { $eq: true } }));
}

Meteor.methods({
  'services.insert'(data) {
    userCheck(['admin','super-admin']);

    Services.insert({
      ...data,
      owner: Meteor.userId(),
    });
  },
  'services.update'(id, data) {
    userCheck(['admin','super-admin']);

    const service = Services.findOne(id);

    if (!service) {
      throw new Meteor.Error(404, NOT_FOUND);
    }

    Services.update(id, { $set: data });
  },
  'services.delete'(id) {
    check(id, String);
    userCheck(['admin','super-admin']);

    const service = Services.findOne(id);

    if (!service) {
      throw new Meteor.Error(404, NOT_FOUND);
    }

    Services.remove(id);
  },
});

export default Services;