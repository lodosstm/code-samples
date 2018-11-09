import React from 'react';
import {connect} from 'react-redux';
import PropTypes from 'prop-types';
import Container from 'layouts/grids/Container';
import ContentContainer from 'layouts/grids/ContentContainer';
import ProjectsListItem from 'components/ProjectListItem';
import ProjectsNavbar from 'components/ProjectsNavbar';
import Layout from 'layouts/templates/Layout';
import {fetchProjects, getFilters, loadMore} from 'actions/index';
import EmptyList from 'components/EmptyList';
import {PROJECTS_LIMIT} from 'constants';
import Metadata from 'components/Metadata';
import './styles.sass';

ProjectsList.defaultProps = {
  projects: [],
  limit: 10,
  onLoadMore: null,
};

ProjectsList.propTypes = {
  projects: PropTypes.arrayOf(PropTypes.shape({})),
  limit: PropTypes.number,
  onLoadMore: PropTypes.func,
};

ProjectsList.getInitialProps = async ({store}) => {
  const projects = await store.dispatch(fetchProjects());
  const filters = await store.dispatch(getFilters());

  return {projects, filters};
};

function ProjectsList({projects, limit, onLoadMore}) {
  const renderList = () => (
    <div className="projects__list">
      {projects.slice(0, limit).map(item => <ProjectsListItem item={item} key={item.id} />)}
      {(projects.length > limit) &&
      <div
        className="projects__loadmore-btn"
        onClick={onLoadMore}
        role="button"
        tabIndex={0}
      >
        Show more {PROJECTS_LIMIT} projects
      </div>
      }
    </div>
  );


  return (
    <Layout pageTitle="Проекты">
      <Metadata
        title="Our works - Lodoss Team"
        indexation="noindex, nofollow"
      />
      <Container className="projects">
        <ContentContainer>
          <ProjectsNavbar
            className="projects__navbar"
            currentViewType="list"
          />
        </ContentContainer>
        {projects.length
          ? renderList()
          : <EmptyList
            title="Something went wrong"
          />
        }
      </Container>
    </Layout>
  );
}

const mapStateToProps = ({portfolio}) => ({
  projects: portfolio.items || [],
  limit: portfolio.itemsLimit,
});
const mapDispatchToProps = dispatch => ({
  onLoadMore: () => {
    dispatch(loadMore());
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(ProjectsList);
