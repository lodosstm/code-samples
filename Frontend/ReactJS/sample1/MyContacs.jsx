import React, {Component} from 'react';
import PropTypes from 'react-proptypes';
import {Button, Col, Modal, ModalBody, ModalFooter, ModalHeader, Row} from 'reactstrap';
import {Link} from 'react-router-dom';
import {bindActionCreators} from 'redux';
import {connect} from 'react-redux';
import Loader from 'react-loader';
import * as actionCreators from '../../actions';
import './MyContacts.css';
import iconDownload from '../../assets/images/download.png';
import noContactsIcon from '../../assets/images/my-contacts-no-contacts.png';
import EditForm from './EditForm';
import EditUrlForm from './EditUrlForm';
import EditPhoneAndEmail from './EditPhoneAndEmail';
import config from '../../config';
import DataGrid, {
    DATAGRID_SELECTED,
    exportAsDate,
    exportAsText,
    renderContactCompany,
    renderContactLocation,
    renderContactName,
    renderContactTitle,
    renderCRM,
    renderDate,
    renderEmail,
    renderIntel,
    renderPhone,
    renderSocialSearch,
    renderStrong,
    renderWebSite,
} from '../DataGrid';
import ValidationForm from '../ValidationForm';

class MyContacts extends Component {
    constructor(props) {
        super(props);
        this.renderHint = this.renderHint.bind(this);
        this.renderNoContacts = this.renderNoContacts.bind(this);
        this.handlePageChange = this.handlePageChange.bind(this);
        this.handleSort = this.handleSort.bind(this);
        this.handleQuickSearchChange = this.handleQuickSearchChange.bind(this);
        this.handleQuickSearchKeyPress = this.handleQuickSearchKeyPress.bind(this);
        this.handleAddContact = this.handleAddContact.bind(this);
        this.handleEditContact = this.handleEditContact.bind(this);
        this.toggleEditForm = this.toggleEditForm.bind(this);
        this.handleEditFormSubmit = this.handleEditFormSubmit.bind(this);
        this.handleEditUrl = this.handleEditUrl.bind(this);
        this.toggleEditUrl = this.toggleEditUrl.bind(this);
        this.handleSubmitUrl = this.handleSubmitUrl.bind(this);
        this.toggleValidationForm = this.toggleValidationForm.bind(this);
        this.toggleEditPhone = this.toggleEditPhone.bind(this);
        this.handleSubmitPhone = this.handleSubmitPhone.bind(this);
        this.toggleEditEmail = this.toggleEditEmail.bind(this);
        this.handleSubmitEmail = this.handleSubmitEmail.bind(this);
        this.selectMultiField = this.selectMultiField.bind(this);
        this.toggleCRMdropdown = this.toggleCRMdropdown.bind(this);
        this.columns = [
            {
                title: 'Name',
                field: 'Name',
                render: renderContactName.bind(this),
                sortable: true,
                export: exportAsText,
                className: 'nowrap',
            },
            {
                title: 'Title',
                field: 'Title',
                render: renderContactTitle.bind(this),
                sortable: true,
                export: exportAsText,
            },
            {
                title: 'Company',
                field: 'Company',
                render: renderContactCompany.bind(this),
                sortable: true,
                export: exportAsText,
            },
            {
                title: 'Website',
                field: 'Website',
                sortable: true,
                render: renderWebSite.bind(this),
                export: exportAsText,
                className: 'nowrap',
            },
            {
                id: 'email',
                title: 'Email',
                field: 'Email',
                sortable: true,
                render: renderEmail.bind(this),
                export: exportAsText,
                className: 'nowrap',
            },
            {
                id: 'phone',
                title: 'Phone',
                field: 'Phone',
                sortable: true,
                render: renderPhone.bind(this),
                export: exportAsText,
            },
            {
                title: 'Social',
                field: 'Social',
                render: renderSocialSearch.bind(this),
                sortable: false,
            },
            {
                title: 'Intel',
                field: 'Intel',
                render: renderIntel.bind(this),
                sortable: false,
            },
            {
                title: 'Location',
                field: 'Location',
                render: renderContactLocation.bind(this),
                sortable: true,
                export: exportAsText,
            },
            {
                title: 'Date',
                field: 'updatedAt',
                render: renderDate,
                sortable: true,
                export: exportAsDate,
            },
            {
                title: 'CRM',
                field: 'SalesforceUrl',
                id: 'crm',
                render: renderCRM.bind(this),
                className: 'text-center',
            },
            {
                title: 'TAGS',
                field: 'tags',
                id: 'tags',
                render: () => '',
            },
        ];
        /**
         * @TODO move this to external service
         */
        this.state = {
            isConfirmDialogOpen: false,
            deleteAll: false,
            totalCount: 0,
            dropdownOpen: {},
        };
    }

    /**
     * Load contacts and crm check on component load
     */
    componentDidMount() {
        const params = new URLSearchParams(this.props.location.search);
        const page = parseInt(params.get('page') || '1', 10);
        const sortField = params.get('sortField') || '';
        const sortOrder = params.get('sortOrder') || '';
        const quickSearch = params.get('search') || '';
        this.props.actions.getMyContacts(page - 1, sortField, sortOrder, quickSearch);
        this.props.actions.crmCheck();

        this.timer = setInterval(() => {
            const { isLoading, isSaving, isSearching, phoneLoading, emailLoading, isValidationOpen, pauseRefresh } = this.props;
            const { dropdownOpen } = this.state;
            let anyDropdowmOpen = false;
            const keys = Object.keys(dropdownOpen);
            for (let i = 0; i < keys.length; i++) {
                const key = keys[i];
                if (dropdownOpen[key] === true) {
                    anyDropdowmOpen = true;
                    break;
                }
            }
            if (
                !isLoading &&
                !isSaving &&
                !isSearching &&
                !phoneLoading &&
                !emailLoading &&
                !isValidationOpen &&
                !pauseRefresh &&
                !anyDropdowmOpen
            ) {
                const { page, sortField, sortOrder, quickSearch } = this.props;
                this.props.actions.getMyContacts(page, sortField, sortOrder, quickSearch, true);
            }
        }, 500000);
    }

    componentWillReceiveProps(nextProps) {
        if (!nextProps.quickSearch) {
            this.setState({
                totalCount: nextProps.total,
            });
        }
    }

    componentWillUnmount() {
        clearInterval(this.timer);
    }

    handlePageChange(page) {
        const { sortField, sortOrder, quickSearch } = this.props;
        this.updateAndRefresh(page, sortField, sortOrder, quickSearch);
    }

    handleSort(sortField, sortOrder) {
        const { page, quickSearch } = this.props;
        this.updateAndRefresh(page, sortField, sortOrder, quickSearch);
    }

    handleQuickSearchChange(event) {
        const { isLoading, page, sortField, sortOrder } = this.props;
        const queryText = event.target.value;
        this.props.actions.myContactsQuickSearch(queryText);
        if (!isLoading) {
            this.updateAndRefresh(page, sortField, sortOrder, queryText);
        }
    }

    handleQuickSearchKeyPress(event) {
        const { isLoading, page, sortField, sortOrder, quickSearch } = this.props;
        if (event.key === 'Enter' && !isLoading) {
            this.updateAndRefresh(page, sortField, sortOrder, quickSearch);
        }
    }

    /**
     * Update location and refresh Contact list
     * @param page
     * @param sortField
     * @param sortOrder
     * @param quickSearch
     */
    updateAndRefresh(page, sortField, sortOrder, quickSearch) {
        const { location, history } = this.props;
        let path = `${location.pathname}?page=${page + 1}`;
        if (sortField) path += `&sortField=${sortField}`;
        if (sortOrder) path += `&sortOrder=${sortOrder}`;
        if (quickSearch) path += `&search=${quickSearch}`;
        history.push(path);
        this.props.actions.getMyContacts(page, sortField, sortOrder, quickSearch);
    }

    /**
     * Import all or selected items
     * @see handleAction(action, all)
     * @param all
     */
    handleImport(all) {
        const { data } = this.props;
        data.forEach((item) => {
            const { sfImport } = item;
            const warning = sfImport && (sfImport.accountDupe || sfImport.contactDupe);
            const error = sfImport && sfImport.error;

            if ((all || item[DATAGRID_SELECTED]) // Skip unselected
                && item.Company && item.Email // Skip broken
                && !item.SalesforceUrl // Skip already connected
                && !warning // Skip dupes
                && !error) { // Skip errors
                this.handleAddContact(item);
            }
        });
    }

    /**
     * Toggle CRM dropdowm
     */
    toggleCRMdropdown(id) {
        const value = this.state.dropdownOpen[id];
        this.setState({
            dropdownOpen: Object.assign({}, this.state.dropdownOpen, { [id]: !value }),
        });
    }

    /**
     * Delete all or selected from my contacts
     * @see handleAction(action, all)
     * @param all
     */
    handleDelete(all) {
        this.setState({
            isConfirmDialogOpen: true,
            deleteAll: all,
        });
    }

    /**
     * Handle action from datagrid
     * @param {string} action action name
     * @param {bool} all import all contacts or selected
     */
    handleAction(action, all) {
        switch (action) {
            case 'import':
                this.handleImport(all);
                break;
            default:
        }
    }

    /**
     * Import provided contact to CRM
     * @param {Object} item contact
     */
    handleAddContact(item, options) {
        this.props.actions.addContact(item, options);
    }

    /**
     * Show contact edit form
     * @param {Object} contact contact
     */
    handleEditContact(contact, field) {
        const { data } = this.props;
        const checked = data.filter(item => item[DATAGRID_SELECTED]);
        this.props.actions.myContactsShowEditForm(checked, contact, field);
    }

    /**
     * Toggle edit form
     */
    toggleEditForm() {
        this.props.actions.myContactsToggleEditForm(!this.props.isEditFormOpen);
    }

    /**
     * Change contact(s) name, title, company, location
     * @param {String} field contact's field to change
     * @param {String} apply to selected or to all
     */
    handleEditFormSubmit({ field, apply }) {
        const editField = this.props.editField;
        if (apply === 'clicked') {
            this.props.actions.editContact({ [editField]: field }, this.props.clickedContact);
        } else {
            this.props.actions.editContacts({ [editField]: field }, this.props.checkedContacts);
        }
    }

    /**
     * Show edit URL form
     * @param {Object} contact
     */
    handleEditUrl(contact) {
        const { data } = this.props;
        const checked = data.filter(item => item[DATAGRID_SELECTED]);
        this.props.actions.myContactsShowEditUrlForm(checked, contact);
    }

    /**
     * Toggle edit URL form
     */
    toggleEditUrl() {
        this.props.actions.myContactsToggleEditUrlForm(!this.props.isEditUrlFormOpen);
    }

    /**
     * Change contact URL (domain)
     * @param {String} domain contact's domain
     */
    handleSubmitUrl({ domain, apply }) {
        if (apply === 'clicked') {
            this.props.actions.editContactUrl(domain, this.props.clickedContact);
        } else {
            this.props.actions.editMultipleUrls(domain, this.props.checkedContacts);
        }
    }

    /**
     * Toggle Validation form
     */
    toggleValidationForm() {
        this.props.actions.myContactsToggleValidationForm(!this.props.isValidationOpen);
    }

    /**
     * Get phone and email validation data
     * @param {Object} item contact
     * @param {itemType} item type
     */
    handleGetValidation(item, itemType) {
        const { data } = this.props;
        const checked = data.filter(item => item[DATAGRID_SELECTED]);
        if (!checked.length) {
            this.props.actions.phoneValidation(item);
            this.props.actions.emailValidation(item);
            this.props.actions.myContactsShowValidationForm(item);
        } else {
            if (itemType === 'phone') {
                this.props.actions.phoneValidation(item, true);
                this.props.actions.myContactsShowPhoneEditForm(checked, item);
            } else {
                this.props.actions.emailValidation(item, true);
                this.props.actions.myContactsShowEmailEditForm(checked, item);
            }
        }
    }

    /**
     * Toggle edit phone form
     */
    toggleEditPhone() {
        this.props.actions.myContactsToggleEditPhoneForm(!this.props.isEditPhoneFormOpen);
    }

    /**
     * Change contact phone (domain)
     * @param {String} apply to selected or to all
     */
    handleSubmitPhone({ apply }) {
        if (apply === 'clicked' && this.state.selectedUsersField) {
            this.props.actions.updatePhone(
                this.props.clickedContact.id,
                this.state.selectedUsersField,
            );
        } else if (apply === 'selected' && this.state.selectedUsersField) {
            this.props.actions.editContactsPhones(
                this.props.checkedContacts,
                this.state.selectedUsersField,
            );
        } else {
            this.toggleEditPhone();
        }
    }

    // email multi select
    /**
     * Toggle edit phone form
     */
    toggleEditEmail() {
        this.props.actions.myContactsToggleEditEmailForm(!this.props.isEditEmailFormOpen);
    }

    /**
     * Change contact phone (domain)
     * @param {String} apply to selected or to all
     */
    handleSubmitEmail({ apply }) {
        if (apply === 'clicked' && this.state.selectedUsersField) {
            this.props.actions.updateEmail(
                this.props.clickedContact.id,
                this.state.selectedUsersField,
            );
        } else if (apply === 'selected' && this.state.selectedUsersField) {
            this.props.actions.editContactsEmails(
                this.props.checkedContacts,
                this.state.selectedUsersField,
            );
        } else {
            this.toggleEditEmail();
        }
    }

    /**
     * Select users phone
     * @param {selectedUser} users fields
     */
    selectMultiField(selectedUsersField) {
        this.setState({ selectedUsersField: selectedUsersField });
    }

    /**
     * Delete contacts
     * @param success
     */
    handleConfirmDelete(success) {
        const { data, page, sortField, sortOrder, quickSearch, actions: { deleteFromMyContacts } } = this.props;
        const { deleteAll } = this.state;
        this.setState({
            isConfirmDialogOpen: false,
        });
        if (success) {
            const ids = deleteAll ? [] : data.filter(item => item[DATAGRID_SELECTED]).map(item => item.id);
            deleteFromMyContacts(ids, deleteAll, { page, sortField, sortOrder, quickSearch });
        }
    }

    /**
     * Render table title
     * @return {*}
     */
    renderHint() {
        const { total, statusText, filterUsed } = this.props;
        if (statusText) {
            return <span>{statusText}</span>;
        }
        if (filterUsed) {
            if (total) {
                return (<span>
          <strong>{total}</strong> contact{total > 1 ? 's' : ''} found.
        </span>);
            } else {
                return <span>No matching data was found.</span>;
            }
        }
        if (total) {
            return (<span>
        You have <strong>{total}</strong> contact{total > 1 ? 's' : ''} saved.
      </span>);
        }
        return null;
    }

    /**
     * render delete confirmation dialog
     * @TODO move this to external service
     * @return {XML}
     */
    renderConfirmDeleteModal() {
        const { deleteAll, isConfirmDialogOpen, totalCount  } = this.state;
        const selected = deleteAll ? [] : this.props.data.filter(item => item[DATAGRID_SELECTED]).length;
        const deleteSelectedText = (
            <p>
                Are you sure you want to delete these contacts (<strong>{selected}</strong>)?
            </p>
        );
        const deleteAllText = (
            <p>
                You are about to delete <strong>{totalCount}</strong> contacts.<br />
            </p>
        );

        return (
            <Modal isOpen={isConfirmDialogOpen} toggle={() => { this.handleConfirmDelete(false); }}>
                <ModalHeader toggle={() => { this.handleConfirmDelete(false); }}>
                    Confirm deletion
                </ModalHeader>
                <ModalBody>
                    {deleteAll ? deleteAllText : deleteSelectedText}
                    <p>
                        {deleteAll ? 'Are you sure you want to delete all contacts? ' : ''}
                        These contacts cannot be restored once deleted.
                    </p>
                </ModalBody>
                <ModalFooter>
                    <Button color="primary" onClick={() => { this.handleConfirmDelete(true); }}>
                        Yes
                    </Button>{' '}
                    <Button color="secondary" onClick={() => { this.handleConfirmDelete(false); }}>
                        Cancel
                    </Button>
                </ModalFooter>
            </Modal>
        );
    }

    renderNoContacts() {
        return (
            <Row className="no-contacts justify-content-center">
                <Col className="col-auto">
                    <div className="d-flex flex-row justify-content-center">
                        <img src={noContactsIcon} alt="no contacts" />
                    </div>
                    <h2 className="w-100 mainTitle text-center">You don&#39;t have any contacts yet!</h2>
                    <div className="text-center mt-4">
                        Connect with over 500M professionals using&nbsp;
                        <Link to="/people">people search</Link> or&nbsp;
                        <Link to="/contacts">contact search</Link> today!
                    </div>
                </Col>
            </Row>
        );
    }

    /**
     * Main render function
     * @return {XML}
     */
    render() {
        const {
            data, total, isLoading, page, sortField, sortOrder, quickSearch, filterUsed, crmConnected, isEditFormOpen,
            isEditUrlFormOpen, isEditPhoneFormOpen, isEditEmailFormOpen, checkedContacts, phoneData, phoneLoading,
            selectedCompanyPhone, selectedContactPhone, contactId, emailData, emailLoading, emailSelected, reloadPhones,
            reloadEmails, isSaving, editField, multi, isValidationOpen, clickedContact,
            actions: { myContactsUpdateData },
        } = this.props;
        const showDataGrid = !!((data && data.length) || filterUsed);
        const datagridActions = [];
        if (crmConnected) {
            datagridActions.push(
                {
                    action: 'import',
                    title: 'Import',
                    iconAll: iconDownload,
                },
            );
        }
        return (
            <div className="table-container">
                <Row>
                    {this.renderConfirmDeleteModal()}
                    <Col lg={12}>
                        <Loader
                            {...config.loader}
                            loaded={!isLoading}
                            className="mt-5"
                        >
                            { showDataGrid ?
                                <DataGrid
                                    data={data}
                                    total={total}
                                    columns={this.columns}
                                    className="my-contacts-table mt-3"
                                    allowChecking
                                    allowDownload
                                    downloadCSVfromBackend
                                    pageName="contacts"
                                    allowQuickSearch
                                    quickSearchPlaceholder="Search Contacts"
                                    hintText={this.renderHint()}
                                    page={page}
                                    serverPagination
                                    sortField={sortField}
                                    sortOrder={sortOrder}
                                    allowDelete
                                    onDelete={all => this.handleDelete(all)}
                                    quickSearch={quickSearch}
                                    filterUsed={filterUsed}
                                    onPageChange={this.handlePageChange}
                                    onQuickSearchChange={this.handleQuickSearchChange}
                                    onQuickSearchKeyPress={this.handleQuickSearchKeyPress}
                                    resultsPerPage={config.resultsPerPage}
                                    onSort={this.handleSort}
                                    onFind={e => this.handleFind(e)}
                                    actions={datagridActions}
                                    onAction={(...args) => this.handleAction(...args)}
                                    onUpdateData={myContactsUpdateData}
                                    csvFileName="contacts.csv"
                                    fullObjectDownload={true}
                                /> :
                                this.renderNoContacts()
                            }
                        </Loader>
                        <ValidationForm
                            isOpen={isValidationOpen}
                            toggle={this.toggleValidationForm}
                            phoneData={phoneData}
                            selectedCompanyPhone={selectedCompanyPhone}
                            selectedContactPhone={selectedContactPhone}
                            contactId={contactId}
                            clickedContact={clickedContact}
                            phoneLoading={phoneLoading}
                            emailData={emailData}
                            emailSelected={emailSelected}
                            emailLoading={emailLoading}
                            reloadPhones={reloadPhones}
                            reloadEmails={reloadEmails}
                            multi={multi}
                        />
                        <Modal isOpen={isEditFormOpen} toggle={this.toggleEditForm} className="edit-form">
                            <ModalHeader toggle={this.toggleEditForm}>Edit {editField}</ModalHeader>
                            <ModalBody>
                                <EditForm
                                    onSubmit={this.handleEditFormSubmit}
                                    checkedContacts={checkedContacts}
                                    isSaving={isSaving}
                                    formTitle={editField}
                                />
                            </ModalBody>
                        </Modal>
                        <Modal isOpen={isEditUrlFormOpen} toggle={this.toggleEditUrl} className="edit-form">
                            <ModalHeader toggle={this.toggleEditUrl}>Edit Website</ModalHeader>
                            <ModalBody>
                                <EditUrlForm
                                    onSubmit={this.handleSubmitUrl}
                                    checkedContacts={checkedContacts}
                                    isSaving={isSaving}
                                />
                            </ModalBody>
                        </Modal>
                        <Modal isOpen={isEditPhoneFormOpen && !phoneLoading} toggle={this.toggleEditPhone} className="edit-form">
                            <ModalHeader toggle={this.toggleEditPhone}>Edit phone</ModalHeader>
                            <ModalBody>
                                <EditPhoneAndEmail
                                    onSubmit={this.handleSubmitPhone}
                                    checkedContacts={checkedContacts}
                                    isSaving={isSaving}
                                    data={phoneData}
                                    selected={
                                        this.state.selectedUsersField ?
                                            this.state.selectedUsersField.Phone :
                                            selectedCompanyPhone}
                                    handleSelect={this.selectMultiField}
                                    handleClose={this.toggleEditPhone}
                                    columns={[
                                        {
                                            title: 'Phone',
                                            field: 'Phone',
                                        },
                                        {
                                            title: 'Total AI',
                                            field: 'Total AI',
                                            render: renderStrong,
                                        },
                                    ]}
                                />
                            </ModalBody>
                        </Modal>
                        <Modal isOpen={isEditEmailFormOpen && !emailLoading} toggle={this.toggleEditEmail} className="edit-form">
                            <ModalHeader toggle={this.toggleEditEmail}>Edit email</ModalHeader>
                            <ModalBody>
                                <EditPhoneAndEmail
                                    onSubmit={this.handleSubmitEmail}
                                    checkedContacts={checkedContacts}
                                    isSaving={isSaving}
                                    data={emailData}
                                    selected={this.state.selectedUsersField ?
                                        this.state.selectedUsersField.Email :
                                        emailSelected}
                                    handleSelect={this.selectMultiField}
                                    handleClose={this.toggleEditEmail}
                                    columns={[
                                        {
                                            title: 'Email',
                                            field: 'Email',
                                        },
                                        {
                                            title: 'Total AI',
                                            field: 'Total AI',
                                            render: renderStrong,
                                        },
                                    ]}
                                />
                            </ModalBody>
                        </Modal>
                    </Col>
                </Row>
            </div>
        );
    }
}

const
    mapStateToProps = state => ({
        statusText: state.myContacts.statusText,
        data: state.myContacts.data,
        total: state.myContacts.total,
        isLoading: state.myContacts.isLoading,
        page: state.myContacts.page,
        sortField: state.myContacts.sortField,
        sortOrder: state.myContacts.sortOrder,
        quickSearch: state.myContacts.quickSearch,
        filterUsed: state.myContacts.filterUsed,
        crmConnected: state.myContacts.crmConnected,
        isEditFormOpen: state.myContacts.isEditFormOpen,
        isEditUrlFormOpen: state.myContacts.isEditUrlFormOpen,
        isValidationOpen: state.myContacts.isValidationOpen,
        isEditPhoneFormOpen: state.myContacts.isEditPhoneFormOpen,
        isEditEmailFormOpen: state.myContacts.isEditEmailFormOpen,
        isSaving: state.myContacts.isSaving,
        checkedContacts: state.myContacts.checkedContacts,
        clickedContact: state.myContacts.clickedContact,
        editField: state.myContacts.field,
        isSearching: state.myContacts.isSearching,
        pauseRefresh: state.myContacts.pauseRefresh,
        phoneData: state.validation.phoneData,
        phoneLoading: state.validation.phoneLoading,
        selectedCompanyPhone: state.validation.selectedCompanyPhone,
        selectedContactPhone: state.validation.selectedContactPhone,
        contactId: state.validation.contactId,
        emailData: state.validation.emailData,
        emailLoading: state.validation.emailLoading,
        emailSelected: state.validation.emailSelected,
        reloadPhones: state.validation.reloadPhones,
        reloadEmails: state.validation.reloadEmails,
        listUpdate: state.validation.listUpdate,
        multi: state.validation.multi,
    });

const
    mapDispatchToProps = dispatch => ({
        actions: bindActionCreators(actionCreators, dispatch),
    });

MyContacts.propTypes = {
    statusText: PropTypes.string,
    data: PropTypes.arrayOf(PropTypes.object),
    total: PropTypes.number,
    isLoading: PropTypes.bool,
    page: PropTypes.number,
    sortField: PropTypes.string,
    sortOrder: PropTypes.string,
    quickSearch: PropTypes.string,
    filterUsed: PropTypes.bool,
    crmConnected: PropTypes.bool,
    isEditFormOpen: PropTypes.bool,
    isEditUrlFormOpen: PropTypes.bool,
    isEditPhoneFormOpen: PropTypes.bool,
    isEditEmailFormOpen: PropTypes.bool,
    isValidationOpen: PropTypes.bool,
    checkedContacts: PropTypes.array,
    clickedContact: PropTypes.object,
    selectedCompanyPhone: PropTypes.string,
    selectedContactPhone: PropTypes.string,
    isSaving: PropTypes.bool,
    isSearching: PropTypes.bool,
    phoneLoading: PropTypes.bool,
    emailLoading: PropTypes.bool,
    pauseRefresh: PropTypes.bool,
    actions: PropTypes.shape({
        getMyContacts: PropTypes.func,
        myContactsQuickSearch: PropTypes.func,
        addContact: PropTypes.func,
        crmCheck: PropTypes.func,
        deleteFromMyContacts: PropTypes.func,
        editContact: PropTypes.func,
        editContacts: PropTypes.func,
        phoneValidation: PropTypes.func,
        emailValidation: PropTypes.func,
        myContactsShowEditForm: PropTypes.func,
        myContactsToggleEditForm: PropTypes.func,
        editContactUrl: PropTypes.func,
        editMultipleUrls: PropTypes.func,
        myContactsShowEditUrlForm: PropTypes.func,
        myContactsToggleEditUrlForm: PropTypes.func,
        myContactsShowPhoneEditForm: PropTypes.func,
        myContactsToggleEditPhoneForm: PropTypes.func,
        myContactsShowEmailEditForm: PropTypes.func,
        myContactsToggleEditEmailForm: PropTypes.func,
        myContactsToggleValidationForm: PropTypes.func,
        myContactsShowValidationForm: PropTypes.func,
        editContactsPhones: PropTypes.func,
        editContactsEmails: PropTypes.func,
        updatePhone: PropTypes.func,
        updateEmail: PropTypes.func,
    }),
};

MyContacts.defaultProps = {
    statusText: '',
    data: [],
    isLoading: false,
    page: 0,
    sortField: 'updatedAt',
    sortOrder: 'desc',
    quickSearch: '',
    filterUsed: false,
    crmConnected: false,
    isSaving: false,
    isSearching: false,
    actions: {},
};

export default connect(mapStateToProps, mapDispatchToProps)(MyContacts);