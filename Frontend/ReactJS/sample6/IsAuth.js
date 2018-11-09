import PropTypes from 'prop-types';
import hasAuth from '../hasAuth';

const propTypes = {
  children: PropTypes.func.isRequired,
  isAuth: PropTypes.bool.isRequired,
};

const isAuth = ({children, isAuth: authorized}) => (
  children({isAuth: authorized})
);

isAuth.propTypes = propTypes;

export default hasAuth(isAuth);
