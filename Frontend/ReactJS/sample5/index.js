import React from 'react';

const withHover = Component => (
  class HoverWrap extends React.Component {
    static displayName = `withHover (${Component.displayName})`;

    state = {
      isHover: false,
    };

    onMouseLeave = () => {
      this.setState({isHover: false});
    };

    onMouseEnter = () => {
      this.setState({isHover: true});
    };

    render() {
      const {isHover} = this.state;

      const componentProps = {
        ...this.props,
        hover: isHover,
        onMouseEnter: this.onMouseEnter,
        onMouseLeave: this.onMouseLeave,
      };

      return (
        <Component {...componentProps} />
      );
    }
  }
);

export default withHover;
