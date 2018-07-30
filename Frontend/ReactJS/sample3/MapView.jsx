import React, { Component } from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import GoogleMap from 'google-map-react';
import { fitBounds } from 'google-map-react/utils';
import { isEqual } from 'lodash';

import {
  GOOGLE_MAPS_STYLES,
  GOOGLE_MAPS_SERVICE_API_KEYS,
  DEFAULT_MAP_CENTER,
  DEFAULT_MAP_ZOOM,
} from 'config/app';

import MapInfoWindow from './MapInfoWindow';

class MapView extends Component {
  constructor(props) {
    super(props);
    this.state = {
      markers: [],
    };
    this.infowindow = null;
    this.map = null;
    this.maps = null;
    this.onChange = this.onChange.bind(this);
    this.onMapLoad = this.onMapLoad.bind(this);
    this.updateMaskers = this.updateMaskers.bind(this);
    this.initializeMapCenterAndZoom = this.initializeMapCenterAndZoom.bind(this);
  }
  componentDidMount() {
    const { businesses } = this.props;
    this.initializeMapCenterAndZoom(businesses);
  }
  componentDidUpdate(prevProps) {
    const {
      getItemId,
    } = this.props;
    const newEntitiesIds = this.props.businesses.map(getItemId).sort();
    const prevEntitiesIds = prevProps.businesses.map(getItemId).sort();

    if (!isEqual(newEntitiesIds, prevEntitiesIds) && this.maps) {
      this.updateMaskers(this.props.businesses);
    }
  }
  onChange({ bounds }) {
    this.props.getItemsByGeoposition(bounds);
  }
  onMapLoad({ map, maps }) {
    this.map = map;
    this.maps = maps;
    this.infowindow = new this.maps.InfoWindow({
      content: '<div id="map-info-window-content"></div>',
    });
    maps.event.addListener(this.map, 'click', () => {
      this.infowindow.close();
    });
    this.updateMaskers(this.props.businesses);
  }
  initializeMapCenterAndZoom(businesses) {
    const businessCount = businesses.length;
    let center = DEFAULT_MAP_CENTER;
    let zoom = DEFAULT_MAP_ZOOM;

    if (businessCount === 1) {
      center = businesses[0].address.geoPosition;
      zoom = 13;
    }

    if (businessCount > 1) {
      const coordinates = businesses.map(business => business.address.geoPosition);
      const northernCoordinate = Math.max(...coordinates.map(c => c.lat));
      const southernCoordinate = Math.min(...coordinates.map(c => c.lat));
      const easternCoordinate = Math.max(...coordinates.map(c => c.lng));
      const westernCoordinate = Math.min(...coordinates.map(c => c.lng));
      const bounds = {
        nw: {
          lat: northernCoordinate,
          lng: westernCoordinate,
        },
        se: {
          lat: southernCoordinate,
          lng: easternCoordinate,
        },
      };
      const {
        offsetWidth,
        offsetHeight,
      } = document.getElementById('business-list-map');
      const mapSize = {
        width: offsetWidth,
        height: offsetHeight,
      };
      ({ center, zoom } = fitBounds(bounds, mapSize));
    }
    this.center = center;
    this.zoom = zoom;
  }
  updateMaskers(businesses) {
    const {
      getItemId,
      getLinkToItem,
      isAddingToFavouriteListsAllowed,
    } = this.props;
    const currentMarkers = this.state.markers;
    const incomeBusinessesIds = businesses.map(getItemId);
    const existingBusinessesIds = currentMarkers.map(getItemId);
    const deletedMarkers = currentMarkers
      .filter(({ business }) => !incomeBusinessesIds.includes(getItemId(business)));
    deletedMarkers.forEach((marker) => {
      marker.setMap(null);
    });
    const newBusinesses = businesses.filter(business =>
      !existingBusinessesIds.includes(getItemId(business)));
    const newMarkers = newBusinesses.map((business) => {
      const marker = new this.maps.Marker({
        position: business.address.geoPosition,
        icon: '../../assets/images/icons/location.svg',
        map: this.map,
        business,
      });
      marker.addListener('click', () => {
        this.infowindow.open(this.map, marker);
        ReactDOM.render(
          <MapInfoWindow
            item={business}
            getLinkToItem={getLinkToItem}
            isAddingToFavouriteListsAllowed={isAddingToFavouriteListsAllowed}
            store={this.context.store}
          />,
          document.getElementById('map-info-window-content')
        );
      });
      marker.addListener('mouseover', () => {
        marker.setZIndex(1);
      });
      marker.addListener('mouseleave', () => {
        marker.setZIndex(0);
      });

      return marker;
    });
    const validExistingMarkers = currentMarkers
      .filter(({ business }) => incomeBusinessesIds.includes(getItemId(business)));
    this.setState({
      markers: [...validExistingMarkers, ...newMarkers],
    });
  }
  render() {
    const {
      center = DEFAULT_MAP_CENTER,
      zoom = DEFAULT_MAP_ZOOM,
      onChange,
    } = this;

    return (
      <div id="business-list-map">
        <GoogleMap
          bootstrapURLKeys={GOOGLE_MAPS_SERVICE_API_KEYS}
          options={{
            styles: GOOGLE_MAPS_STYLES,
          }}
          center={center}
          zoom={zoom}
          onChange={onChange}
          onGoogleApiLoaded={this.onMapLoad}
          yesIWantToUseGoogleMapApiInternals
        />
      </div>
    );
  }
}

export default MapView;

MapView.propTypes = {
  getItemsByGeoposition: PropTypes.func.isRequired,
  businesses: PropTypes.arrayOf(PropTypes.shape({})).isRequired,
  getItemId: PropTypes.func,
  getLinkToItem: PropTypes.func.isRequired,
  isAddingToFavouriteListsAllowed: PropTypes.bool,
};
MapView.defaultProps = {
  getItemId: ({ id }) => id,
  isAddingToFavouriteListsAllowed: true,
};
MapView.contextTypes = {
  store: React.PropTypes.object,
};
