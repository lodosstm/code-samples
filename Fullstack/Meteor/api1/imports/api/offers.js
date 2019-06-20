import { Meteor } from 'meteor/meteor';
import { check } from 'meteor/check';
import { errors } from '../../constants';
import { userCheck } from '../../security';
import { Offers } from '../../collections';

const {
  NOT_FOUND,
  ACCEPTED_ALREADY,
} = errors;

if (Meteor.isServer) {
  Meteor.publish('offers', () => Offers.find({
    userId: Meteor.userId(),
    isActive: { $eq: true }
  }));
}

Meteor.methods({
  'offers.add'(data) {
    userCheck('*');

    Offers.insert({
      ...data,
      userId: Meteor.userId(),
    });
  },
  'Offers.update'(id, data) {
    userCheck('*');

    const offer = Offers.findOne(id);

    if (!offer || offer.userId !== Meteor.userId()) {
      throw new Meteor.Error(404, NOT_FOUND);
    }

    Offers.update(id, { $set: data });
  },
  'Offers.delete'(id) {
    check(id, String);
    userCheck('*');

    const offer = Offers.findOne(id);

    if (!offer || offer.userId !== Meteor.userId()) {
      throw new Meteor.Error(404, NOT_FOUND);
    }

    if (offer.isAccepted) {
      throw new Meteor.Error(403, ACCEPTED_ALREADY);
    }

    Offers.remove(id);
  },
});

export default Offers;