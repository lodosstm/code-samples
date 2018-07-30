import React from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import getMuiTheme from 'material-ui/styles/getMuiTheme';

import BeenToButton from 'components/common/buttons/BeenToButton';
import { Location } from 'assets/icons/index';

import AddToFavouriteBtn from './AddToFavouriteBtn';

const MapInfoWindow = ({ item, getLinkToItem, isAddingToFavouriteListsAllowed, ...restProps }) => {
  const {
    name,
    businessType,
    address,
    photos,
  } = item;
  const itemId = item.entityId || item.id;
  const itemType = item.type || 'businesses';

  return (
    <MuiThemeProvider muiTheme={getMuiTheme(null, { userAgent: 'all' })}>
      <div className="map-info-tooltip__body">
        <h3 className="map-info-tooltip__title">
          <a href={getLinkToItem(item)}>{name}</a>
          <ul className="map-info-tooltip__buttons">
            <li className="map-info-tooltip__button">
              {isAddingToFavouriteListsAllowed && <AddToFavouriteBtn
                name={item.name}
                imageUrl={item.photos.find(photo => photo.index === 0).url}
                address={item.address}
                entityType={itemType}
                entityId={itemId}
                isUserFoodEnthisuast
                {...restProps}
              />}
            </li>
            <li className="map-info-tooltip__button">
              <BeenToButton
                itemId={itemId}
                itemType={itemType}
                className="map-info-tooltip__consumer-icon"
                {...restProps}
              >
                <Location className="icon" />
              </BeenToButton>
            </li>
          </ul>
        </h3>
        <ul className="map-info-tooltip__subtitle">
          <li className="map-info-tooltip__subtitle-item">{businessType.name}</li>
          <li className="map-info-tooltip__subtitle-item">{address.locality}</li>
        </ul>
        <img
          className="map-info-tooltip__picture"
          src={photos.find(({ index }) => index === 0).url}
          alt={name}
        />
      </div>
    </MuiThemeProvider>
  );
};

export default MapInfoWindow;
