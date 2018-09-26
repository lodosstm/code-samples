import Vue from 'vue';
import Vuex from 'vuex';
import firebaseApp from '@/firebase';
import router from '@/router';
import { firebaseRefs, emptyProject } from '@/config';


Vue.use(Vuex);

const db = firebaseApp.database();

const store = () => new Vuex.Store({
    state: {
        user: {},
        projects: [],
        preparedProjects: [],
        tags: {},
        typeTags: {},
        project: {},
    },
    getters: {
        getProjects: state => state.projects,
        getTags: state => state.tags,
        getTypeTags: state => state.typeTags,
        getProject: state => state.project,
        getUser: state => state.user,
    },
    mutations: {
        SET_USER(state, user) {
            state.user = user;
        },
        GET_PROJECTS(state, projects) {
            const values = Object.values(projects);
            const keys = Object.keys(projects);
            values.forEach((el, index) => {
                values[index].id = keys[index];
                return el;
            });
            state.projects = values;
        },
        GET_PROJECT(state, project) {
            const newProject = Object.assign({}, emptyProject);
            state.project = Object.assign(newProject, project);
        },
        REMOVE_PROJECT(state) {
            state.project = Object.assign({}, emptyProject);
        },
        GET_TAGS(state, passedTags) {
            state.tags = passedTags;
        },
        GET_TYPE_TAGS(state, passedTags) {
            state.typeTags = passedTags;
        },
    },
    actions: {
        setUser({ commit }, user) {
            commit('SET_USER', user);
        },
        getProjects({ commit }) {
            db.ref(firebaseRefs.projects).on('value', (snapshot) => {
                let result = snapshot.val();
                if (!result) {
                    result = {};
                }
                commit('GET_PROJECTS', result);
            }, (errorObject) => {
                // eslint-disable-next-line no-console
                console.log('The read failed: ', errorObject.code);
            });
        },
        getProject({ commit }, id) {
            if (id) {
                const path = [firebaseRefs.projects, id].join('/');
                db.ref(path).once('value').then((data) => {
                    let res = data.val();
                    if (!res) {
                        res = Object.assign({}, emptyProject);
                    }
                    commit('GET_PROJECT', res);
                });
            } else {
                commit('GET_PROJECT', emptyProject);
            }
        },
        getTags({ commit }) {
            db.ref(firebaseRefs.techTags).on('value', (snapshot) => {
                let result = snapshot.val();
                if (!result) {
                    result = {};
                }
                commit('GET_TAGS', result);
            }, (errorObject) => {
                // eslint-disable-next-line no-console
                console.log('The read failed: ', errorObject.code);
            });
        },
        getTypeTags({ commit }) {
            db.ref(firebaseRefs.typeTags).on('value', (snapshot) => {
                let result = snapshot.val();
                if (!result) {
                    result = {};
                }
                commit('GET_TYPE_TAGS', result);
            }, (errorObject) => {
                // eslint-disable-next-line no-console
                console.log('The read failed: ', errorObject.code);
            });
        },
        addTechTag({ commit }, tag) {
            const newTagRef = db.ref(firebaseRefs.techTags).push();
            newTagRef.set(tag);
        },
        addTypeTag({ commit }, tag) {
            const newTagRef = db.ref(firebaseRefs.typeTags).push();
            newTagRef.set(tag);
        },
        removeTag({ commit }, tag) {
            let path = '';
            if (tag.tagID) {
                switch (tag.type) {
                    case 'tags':
                        path = [firebaseRefs.typeTags, tag.tagID].join('/');
                        break;
                    case 'tech_tags':
                        path = [firebaseRefs.techTags, tag.tagID].join('/');
                        break;
                    default :
                        break;
                }
                db.ref(path).remove();
            }
        },
        addProject({ commit }, project) {
            const newProjectRef = db.ref(firebaseRefs.projects).push();
            newProjectRef.set(project);

            router.push({ name: 'EditProject', params: { id: newProjectRef.key } });
        },
        updateProject({ commit }, data) {
            if (data.id) {
              const path = [firebaseRefs.projects, data.id].join('/');
              db.ref(path).set(data.project);
            }
        },
        removeProject({ commit }, id) {
            if (id) {
                const path = [firebaseRefs.projects, id].join('/');
                db.ref(path).remove();

                commit('REMOVE_PROJECT');

                router.push('/dashbord');
            }
        },
    },
});

export default store;
