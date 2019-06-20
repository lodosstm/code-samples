import { Meteor } from 'meteor/meteor';
import { Mongo } from 'meteor/mongo';
import schemas from '../../schemas';
import { sendEmail } from '../../libs';
import Services from './services';

const Offers = new Mongo.Collection('offers');
Offers.attachSchema(schemas.offers);

const notifyServiceOwner = (tpl, serviceId) => {
  const { owner } = Services.findOne(serviceId);
  sendEmail(tpl, { userId: owner, doc });
};

Offers.after.insert((userId, doc) => {
  const { serviceId } = doc;
  notifyServiceOwner('offer-received', serviceId);
});

Offers.after.remove((userId, doc) => {
  const { serviceId } = doc;
  sendEmail('offer-has-deleted', { userId, doc });
  notifyServiceOwner('offer-has-deleted', serviceId);
});

export default Services;