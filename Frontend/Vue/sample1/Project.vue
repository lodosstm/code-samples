<template>
    <div class="add-project">
        <div class="subheader">
            <div class="subheader-title">
                <h1>
                    <router-link to="/dashbord">Dashbord</router-link> >
                    <span v-if="id">Edit project</span>
                    <span v-if="!id">Create project</span>
                </h1>
            </div>
        </div>
        <div class="form-container">
            <main>
                <div class="form-container-group">
                    <label for="title">Title</label>
                    <input v-model="project.title" class="form-control" placeholder="Title" id="title">
                </div>
                <div class="form-container-group">
                    <label for="website-link">Website Link</label>
                    <input v-model="project.website_link" class="form-control" placeholder="Website Link" id="website-link">
                </div>
                <div class="form-container-group">
                    <label for="app-store">App store</label>
                    <input v-model="project.app_store" class="form-control" placeholder="App store" id="app-store">
                </div>
                <div class="form-container-group">
                    <label for="google-play">Google Play</label>
                    <input v-model="project.google_play" class="form-control" placeholder="Google Play" id="google-play">
                </div>
                <div class="form-container-group">
                    <label for="short-description">Short Description</label>
                    <textarea v-model="project.short_description" class="form-control" rows="3" placeholder="Short Description" id="short-description"></textarea>
                </div>
                <div class="form-container-group">
                    <label for="long-description">Long Description</label>
                    <textarea v-model="project.long_description" class="form-control" rows="12" placeholder="Long Description" id="long-description"></textarea>
                </div>
                <div class="form-container-group">
                    <label for="what-we-did">What we did on the project</label>
                    <textarea v-model="project.what_we_did" class="form-control" rows="5" placeholder="What we did on the project" id="what-we-did"></textarea>
                </div>
                <div class="form-container-group">
                    <label for="additional-info">Additional info</label>
                    <textarea v-model="project.additional_info" class="form-control" rows="5" placeholder="Additional info" id="additional-info"></textarea>
                </div>

                <h2>Technologies Tags</h2>
                <div>
                    <tags
                            :project-tags="project.tech_tags"
                            :tags="tags"
                            :type="'tech_tags'"
                            @select="select"
                            @addtag="addTechTagFunc"
                            @removetag="removeTagFunc"
                    ></tags>
                </div>

                <h2>Type Tags</h2>
                <div>
                    <tags
                            :project-tags="project.tags"
                            :tags="typeTags"
                            :type="'tags'"
                            @select="select"
                            @addtag="addTypeTag"
                            @removetag="removeTagFunc"
                    ></tags>
                </div>
                <h2>Client</h2>
                <div class="form-container-group">
                    <label for="client-name">Name</label>
                    <input v-model="project.client_name" class="form-control" placeholder="Name" id="client-name">
                </div>
                <div class="form-container-group">
                    <label for="client-email">Email</label>
                    <input v-model="project.client_email" type="email" class="form-control" placeholder="Email" id="client-email">
                </div>
                <div class="form-container-group">
                    <label for="client-skype">Skype</label>
                    <input v-model="project.client_skype" class="form-control" placeholder="Skype" id="client-skype">
                </div>
                <div class="button-container">
                    <div class="container">
                        <button
                                @click="addProjectFunc()"
                                :disabled="!canSave"
                                class="btn btn--primary">SAVE</button>
                        <button
                                @click="removeProjectFunc(id)"
                                v-if="id"
                                class="btn btn-color--danger"><i class="fas fa-trash"></i> REMOVE</button>
                    </div>
                </div>
            </main>
        </div>
    </div>
</template>

<script>
    import { project } from '@/config';
    import { mapGetters, mapActions } from 'vuex';
    import Tags from '@/components/shared/Tags';
    import _ from 'lodash';
    import { emptyProject } from '@/config';

    export default {
        name: 'Project',
        components: {
            Tags,
        },
        computed: {
            ...mapGetters({
                project: 'getProject',
                tags: 'getTags',
                typeTags: 'getTypeTags',
            }),
            ...mapActions([
                'getTags',
                'getTypeTags',
            ]),
            id: function() {
                return this.$route.params.id;
            },
            canSave: function() {
                return (
                    this.project.title !== '' &&
                    this.project.website_link !== '' &&
                    (this.project.tech_tags.length > 0 || this.project.tags.length > 0)
                );
            }
        },
        created() {
            // getting data from DB
            this.getProject(this.id);
            this.getTags;
            this.getTypeTags;
        },
        watch: {
            // do redirect if wrong link
            project(data) {
                if (this.id && data.title === '') {
                    this.$router.push('/dashbord');
                }
            },
            $route (to, from) {
                if (to.name === 'NewProject') {
                    this.getProject(false);
                } else {
                    this.getProject(to.params.id);
                }
            }
        },
        methods: {
            select: function(type, tag) {
                const index = _.indexOf(this.project[type], tag);
                if (index === -1) {
                    this.project[type].push(tag);
                } else {
                    this.project[type].splice(index, 1);
                }
            },
            addProjectFunc: function() {
                let newProject  = Object.assign({},emptyProject);
                newProject = Object.assign(newProject, this.project);
                if (this.id) {
                    this.updateProject({project:newProject, id:this.id});
                } else {
                    this.addProject(newProject);
                }
            },
            addTypeTag: function(value) {
                this.addTechTag(value);
            },
            addTechTagFunc: function(value) {
                this.addTechTag(value);
            },
            removeTagFunc: function(type, tagID){
                this.removeTag({type, tagID});
            },
            removeProjectFunc: function(id) {
                this.removeProject(id);
            },
            ...mapActions([
                'addTechTag',
                'addTypeTag',
                'removeTag',
                'addProject',
                'getProject',
                'updateProject',
                'removeProject',
            ]),
        },
    };
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss" scoped>
    @import './project.scss';
</style>
