<template>
  <div class="dashboard">
    <div class="subheader">
      <div class="subheader-title">
        <h1><i class="fas fa-address-card"></i> Projects</h1>
      </div>
    </div>
    <router-link class="btn btn--round btn--negative create" to="project"><i class="fas fa-plus"></i></router-link>
    <div class="search-container">
      <i class="fas fa-search"></i>
      <input class="search-container-field" placeholder="Type here for search" v-model="filterTerm" type="text">
    </div>
    <div class="result">
      <table v-if="filteredList.length !== 0" class="tbl">
        <tr>
          <th width="10%">Title</th>
          <th width="20%">Link</th>
          <th width="30%">Tech tags</th>
          <th width="30%">Type tags</th>
          <th width="10%">Actions</th>
        </tr>
        <tr v-for="project in filteredList" :key="project.id">
          <td>{{project.title}}</td>
          <td>{{project.website_link}}</td>
          <td><Tagsview :tags="project.tech_tags" /></td>
          <td><Tagsview :tags="project.tags" /></td>
          <td><i class="far fa-edit"></i> <router-link :to="{ name: 'EditProject', params: { id: project.id } }">EDIT</router-link></td>
        </tr>
      </table>
      <h2 v-if="filteredList.length === 0" class="no-projects">No projects</h2>
    </div>
  </div>
</template>

<script>
import firebaseApp from '@/firebase';
import { mapGetters, mapActions } from 'vuex';
import Tagsview from '@/components/shared/Tagsview';

export default {
  name: 'Dashbord',
  data: () => {
      msg: 'Welcome to Your Vue.js App',
      filterTerm: '',
  },
  components: {
    Tagsview,
  },
  computed: {
    ...mapGetters({
      projects: 'getProjects',
    }),
    filteredList() {
      return this.projects.filter(project => {
        let searchString = '';
        if(project.title) {
          searchString = [searchString, project.title].join(', ');
        }
        if(project.tags) {
          searchString = [searchString, project.tags.join(',')].join(', ');
        }
        if(project.tech_tags) {
          searchString = [searchString, project.tech_tags.join(',')].join(', ');
        }
        return searchString.toLowerCase().includes(this.filterTerm.toLowerCase())
      });
    },
  },
  created: function() {
    this.getProjects();
  },
  methods: {
    ...mapActions([
      'getProjects',
    ]),
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
  @import './dashboard.scss';
</style>
