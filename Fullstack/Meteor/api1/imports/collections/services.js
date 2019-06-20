import { Mongo } from 'meteor/mongo';
import schemas from '../../schemas';
import Offers from './offers';

const Services = new Mongo.Collection('services');
Services.attachSchema(schemas.service);

Services.after.remove((userId, doc) => {
  Offers.remove({ serviceId: doc.serviceId });
});

export default Services;