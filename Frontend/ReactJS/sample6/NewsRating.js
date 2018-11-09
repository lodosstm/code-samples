import React from 'react';
import PropTypes from 'prop-types';
import {NewsRating as NewsRatingContainer, IsAuth, authModal} from 'containers';
import {RateButtons, Restrict} from 'components';
import {openModal} from 'actions/index';
import {SIGN_IN_FORM_NAME, SIGN_IN_MODAL} from 'constants/index';

const defaultProps = {
  id: null,
  onTabClick: null,
  className: null,
};

const propTypes = {
  id: PropTypes.number,
  onTabClick: PropTypes.func,
  className: PropTypes.string,
};

const NewsRating = (props) => {
  const {
    id,
    onTabClick,
    dispatch,
    className,
  } = props;

  const handleRestriction = () => {
    onTabClick(SIGN_IN_FORM_NAME);
    dispatch(openModal({modal: SIGN_IN_MODAL}));
  };

  return (
    <IsAuth>
      {({isAuth}) => (
        <Restrict
          className={className}
          isAllowed={isAuth}
          onNotAllowed={handleRestriction}
        >
          <NewsRatingContainer id={id}>
            {({rate, ...rest}) => (
              <RateButtons
                {...rate}
                {...rest}
              />
            )}
          </NewsRatingContainer>
        </Restrict>
      )}
    </IsAuth>
  );
};

NewsRating.propTypes = propTypes;
NewsRating.defaultProps = defaultProps;

export default authModal(NewsRating);
