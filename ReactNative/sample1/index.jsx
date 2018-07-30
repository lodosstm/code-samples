import React from 'react';
import PropTypes from 'prop-types';
import { ScrollView, KeyboardAvoidingView, View, Text, Image } from 'react-native';
import { connect } from 'react-redux';
import Stars from 'react-native-stars-rating';
import moment from 'moment';
import { Ionicons } from '@expo/vector-icons';
import { changeRecipeFields, saveRecipe } from '../../actions';
import TextField from '../../components/TextField';
import defaultImage from '../../assets/images/splash.png';
import styles from './styles';

class RecipeDetail extends React.Component {

  componentDidMount() {
    const { navigation: { setParams } } = this.props;
    setParams({ saveRecipe: this.onSaveRecipe });
  }

  onSaveRecipe = () => {
    const { saveRecipe, list } = this.props;
    const { recipeId } = this.props.navigation.state.params;
    const recipeItem = list[recipeId];

    saveRecipe(recipeItem, recipeId);
  };

  getDate = (timestamp) => {
    return timestamp ? moment(timestamp).format('MMM DD, YYYY') : null;
  };

  onChangeValue = (val, type) => {
    const { changeRecipeFields, navigation } = this.props;
    const { recipeId } = navigation.state.params;

    changeRecipeFields(val, type, recipeId);
  };

  render() {
    const {
      container,
      detailImageContainer,
      formContainer,
      detailImage,
      sectionTitle,
      sectionWrap,
      nameInput,
      row,
      separator,
      fieldWrap,
      inlineText,
      recipeDate
    } = styles;

    const { list } = this.props;
    const { recipeId } = this.props.navigation.state.params;
    const recipeItem = list[recipeId];

    return (
      <KeyboardAvoidingView behavior='padding' style={container}>
        <ScrollView>
          <View style={detailImageContainer}>
            {
              <Image
                source={defaultImage}
                style={detailImage}
                resizeMode='cover'
              />
            }
          </View>
          <View style={formContainer}>
            <View style={[ row, fieldWrap ]}>
              <Text>Rating:</Text>
              <View style={separator}>
                <Stars
                  isActive={true}
                  rateMax={5}
                  size={30}
                  rate={recipeItem.rating}
                  onStarPress={(rating) => this.onChangeValue(rating, 'rating')}
                />
              </View>
            </View>
            <TextField
              value={recipeItem.name}
              name='name'
              onChangeText={this.onChangeValue}
              placeholder='Name your journal entry'
              InputStyle={nameInput}
              containerStyle={fieldWrap}
            />
            <Text style={[ inlineText, fieldWrap, recipeDate ]}>{this.getDate(recipeItem.timestamp)}</Text>
            <View style={[ row, fieldWrap ]}>
              <Text style={inlineText}>Yield:</Text>
              <View style={separator}>
                <TextField
                  value={recipeItem.yield}
                  name='Yield'
                  onChangeText={this.onChangeValue}
                  placeholder='Yield'
                />
              </View>
            </View>
            <TextField
              value={recipeItem.ingredients}
              name='ingredients'
              onChangeText={this.onChangeValue}
              placeholder='Ingredients'
              label='Ingredients'
              labelStyle={sectionTitle}
              containerStyle={sectionWrap}
            />
            <TextField
              value={recipeItem.directions}
              name='directions'
              onChangeText={this.onChangeValue}
              placeholder='Directions'
              label='directions'
              labelStyle={sectionTitle}
              containerStyle={sectionWrap}
            />
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    );
  }
}

function mapStateToProps({ recipes }) {
  const { list, error, loading } = recipes;
  return { list, error, loading }
}

const propTypes = {
  list: PropTypes.object,
  changed: PropTypes.bool,
  loading: PropTypes.bool
};

const defaultProps = {
  list: {},
  changed: false,
  loading: false
};

RecipeDetail.propTypes = propTypes;
RecipeDetail.defaultProps = defaultProps;

export default connect(mapStateToProps, { changeRecipeFields, saveRecipe })(RecipeDetail);
