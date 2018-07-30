import React, {Component} from 'react';
import PropTypes from 'react-proptypes';
import classNames from 'classnames';
import {Col, Form, Input, Row, Table} from 'reactstrap';
import Pagination from '../Pagination';
import './DataGrid.css';
import config, {routes} from '../../config';
import ActionButton from './ActionButton';
import QuickSearch from './QuickSearch';
import iconCheck from '../../assets/images/check.png';
import iconDownload from '../../assets/images/download.png';
import {downloadAsFile, escapeForCSV, setArrayItem} from '../../utils';
import {fetchBackEndJson} from '../../utils/index';

export const DATAGRID_SELECTED = '_DATAGRID_SELECTED__';

class DataGrid extends Component {
    constructor(props) {
        super(props);
        this.cntSelected = 0;
        this.excludedFullDownloadFields = ['id', 'isInProgress', '_DATAGRID_SELECTED__'];
    }

    /**
     * Filter data with quick search form
     * @param data
     */
    quickSearchFilter(data) {
        const { columns, quickSearch } = this.props;
        return data.filter((item) => {
            for (const col of columns) {
                if (!col.field || (typeof item[col.field] === 'undefined') || typeof item[col.field] !== 'string') {
                    continue;
                }
                if (item[col.field].toLowerCase().indexOf(quickSearch.toLowerCase()) !== -1) {
                    return true;
                }
            }
            return false;
        });
    }

    /**
     * Calculate selected field to local property
     */
    calculateSelected() {
        this.cntSelected = this.props.data.filter(item => item[DATAGRID_SELECTED]).length;
    }

    /**
     * handle select/unselect all items
     * @param e
     */
    handleCheckAll(e) {
        const { data, onUpdateData } = this.props;
        const checked = e.target.checked;
        onUpdateData(data.map((item) => {
            item[DATAGRID_SELECTED] = checked;
            return item;
        }));
    }

    /**
     * Download selected data as CSV file
     */
    async handleDownload(all) {
        const { data, allowDownload, columns, csvFileName, fullObjectDownload, pageName } = this.props;
        if (this.props.downloadCSVfromBackend && all) {
            const mapping = {
                contacts: routes.CONTACTS_CSV_FILE,
                companies: routes.COMPANIES_CSV_FILE,
            };
            try {
                let url;
                if (pageName === 'contacts') {
                    const csvToken = await fetchBackEndJson.get(routes.CONTACTS_CSV);
                    url = `${mapping[pageName]}?token=${csvToken.token}`;
                } else if (pageName === 'companies') {
                    let token = localStorage.getItem('token');
                    if (token) {
                        const parted = token.split(' ');
                        if (parted.length === 2) {
                            token = parted[1];
                        }
                    }
                    url = `${mapping[pageName]}?token=${token}`;
                }
                return downloadAsFile(this.props.csvFileName, url, true);
            } catch (err) {
                // TODO: Show message in global error handler
                return console.error('Error getting CSV:', err);
            }
        }
        const delimiter = config.csv.delimiter;
        if (!allowDownload) {
            return;
        }
        const exportedCold = columns.filter(item => item.field && item.export);
        let csv = (pageName === 'contacts') ? 'image,' : '';
        let isFirst = true;
        exportedCold.forEach((col) => {
            csv = csv + (isFirst ? '' : delimiter) + col.title;
            isFirst = false;
        });
        let otherKeys = [];
        if (fullObjectDownload) {
            let keys = Object.keys(data[0] || {});
            otherKeys = keys.filter(key => !this.excludedFullDownloadFields.includes(key) && !exportedCold.some(col => col.field === key) && key !== 'image');
        }
        csv += otherKeys.length ? `,${otherKeys.join(delimiter)}` : '';
        csv += '\n';

        data.forEach((item) => {
            // Skip unselected;
            if (!(all || item[DATAGRID_SELECTED])) {
                return;
            }
            if (pageName === 'contacts') csv += `${item['image']},`;
            isFirst = true;
            exportedCold.forEach((col) => {
                csv = csv + (isFirst ? '' : delimiter) +
                    escapeForCSV(col.export(item[col.field]));
                isFirst = false;
            });
            otherKeys.forEach(key => csv += `${delimiter}${escapeForCSV(item[key])}`);
            csv += '\n';
        });

        downloadAsFile(csvFileName, csv);
    }

    /**
     * Handle delete action
     * @param event
     * @param all
     */
    handleDelete(event, all) {
        event.preventDefault();
        this.props.onDelete(all);
    }

    /**
     * Handle select action
     * @param allowSelecting
     */
    handleSelect(allowSelecting, item) {
        if (allowSelecting) {
            this.props.onSelect(item);
        }
    }

    /**
     * Render quick search button
     */
    renderQuickSearch() {
        const { quickSearchPlaceholder, quickSearch, onQuickSearchChange, onQuickSearchKeyPress, serverPagination }
            = this.props;
        return (
            <QuickSearch
                placeholder={quickSearchPlaceholder}
                value={quickSearch}
                onChange={onQuickSearchChange}
                onKeyPress={onQuickSearchKeyPress}
                debounced={serverPagination}
            />
        );
    }


    /**
     * Render one row of table
     * @param item
     * @param i
     * @return {XML}
     */
    renderRow(item, i) {
        const { columns, allowChecking, allowSelecting, rowClassName, onUpdateData,
            data, selectedItem } = this.props;
        return (
            <tr
                key={i}
                className={rowClassName}
                onClick={e => this.handleSelect(allowSelecting, item)}
            >
                { allowChecking || allowSelecting
                    ? <td key={`${i}_check`} className={allowSelecting ? 'borderNone' : ''}>
                        { allowChecking &&
                        <input
                            type="checkbox"
                            checked={
                                typeof item[DATAGRID_SELECTED] !== 'undefined' && item[DATAGRID_SELECTED]
                            }
                            onChange={(e) => {
                                // e.preventDefault();
                                const index = data.indexOf(item);
                                item[DATAGRID_SELECTED] = e.target.checked;
                                onUpdateData(setArrayItem(data, index, item));
                            }}
                        />
                        }
                        { allowSelecting &&
                        <input
                            type="radio"
                            checked={item.Phone === selectedItem || item.Email === selectedItem}
                            onChange={() => 0} /* onSelect is already invoked by onClick above */
                        />
                        }
                    </td>
                    : null
                }
                { columns.map((col, num) => {
                    const cellId = `cell_${i}_${num}`;
                    return (
                        <td key={num} className={col.className} id={cellId}>
                            {
                                col.render ?
                                    col.render(item[col.field], item, cellId) : // custom renderer
                                    item[col.field] // default renderer
                            }
                        </td>
                    );
                })
                }
            </tr>
        );
    }

    /**
     * Render Download button
     */
    renderDownload() {
        const count = this.cntSelected;
        return (
            <div className="d-flex">
                {count
                    ? <ActionButton
                        onClick={() => this.handleDownload(false)}
                        icon={iconCheck}
                    >
                        Download Selected ({count})
                    </ActionButton>
                    : null
                }
                <ActionButton
                    onClick={() => this.handleDownload(true)}
                    icon={iconDownload}
                >
                    Download All
                </ActionButton>
            </div>
        );
    }

    /**
     * Render Actions buttons
     */
    renderActionsBtns() {
        const { onAction, actions } = this.props;
        const buttons = [];
        const count = this.cntSelected;
        actions.forEach((action) => {
            if (count) {
                buttons.push(
                    <ActionButton
                        key={`${action.action}_sel`}
                        onClick={() => onAction(action.action, false)}
                        icon={action.iconSel || iconCheck}
                    >
                        {`${action.title} Selected (${count})`}
                    </ActionButton>,
                );
            }
            /*buttons.push(
              <ActionButton
                key={`${action.action}_all`}
                onClick={() => onAction(action.action, true)}
                icon={action.iconAll}
              >
                {`${action.title} All`}
              </ActionButton>,
            );*/
        });

        return buttons;
    }

    /**
     * Render TH row
     * @return {XML}
     */
    renderHeader() {
        const { data, columns, allowChecking, onSort, sortField, sortOrder, allowSorting, allowSelecting } = this.props;
        if (data.length === 0) return null;
        const renderCell = (item, i) => (
            <th
                key={i}
                onClick={() => {
                    if (!(allowSorting && item.sortable)) return;
                    onSort(item.field, (item.field === sortField && sortOrder === 'asc') ? 'desc' : 'asc');
                }}
            >
                <span className={classNames({ 'text-uppercase headerText': 1 })}>{item.title}</span>
                <span className={classNames({
                    'text-uppercase small': 1,
                    sortable: allowSorting && item.sortable,
                    'sort-asc': allowSorting && item.sortable && item.field === sortField && sortOrder === 'asc',
                    'sort-desc': allowSorting && item.sortable && item.field === sortField && sortOrder === 'desc',
                    'allow-sort': allowSorting && item.sortable && item.field !== sortField,
                })} />
            </th>
        );
        return (
            <tr>
                { allowChecking || allowSelecting
                    ? <th key="th">
                        {allowChecking && <Input type="checkbox" onChange={e => this.handleCheckAll(e)} />}
                    </th>
                    : null
                }
                {columns.map(renderCell)}
            </tr>
        );
    }

    renderDelete() {
        const count = this.cntSelected;
        return (
            <span className="delete-actions">
        { count > 0 &&
        <a href="" role="button" onClick={e => this.handleDelete(e, false)}>
            Delete Selected
        </a>
        }
                <a href="" role="button" onClick={e => this.handleDelete(e, true)}>Delete All</a>
      </span>
        );
    }

    render() {
        const { resultsPerPage, data, total, className, allowQuickSearch, filterUsed, actions,
            allowDownload, hintText, page, onPageChange, quickSearch, sortField, sortOrder, allowDelete,
            allowPagination, allowSorting, quickSearchOnTop, serverPagination } = this.props;
        // Quick filter items
        let filtered = (allowQuickSearch && quickSearch && !serverPagination) ? this.quickSearchFilter(data) : data;
        // Sort data
        if (allowSorting && sortField) {
            const map = filtered.map((item, i) => ({ index: i, value: item[sortField] }));
            map.sort((a, b) => (+(a.value > b.value) || +(a.value === b.value) - 1) * (sortOrder === 'asc' ? 1 : -1));
            filtered = map.map(e => filtered[e.index]);
        }
        // Slice array
        let items = [];
        let pages = [];
        let totalItems = 0;
        if (serverPagination) {
            items = filtered;
            pages = Math.ceil(total / resultsPerPage);
            totalItems = total;
        } else {
            items = allowPagination ? filtered.slice(page * resultsPerPage, (page + 1) * resultsPerPage) : data;
            pages = Math.ceil(filtered.length / resultsPerPage);
            totalItems = filtered.length;
        }
        const showResults = data.length > 0;
        if (allowDownload || actions.length || allowDelete) this.calculateSelected();
        return (
            <Row className={`data-grid ${className}`}>
                <Col lg={12}>
                    <Row className="align-items-center justify-content-between mb-2">
                        <div className="hint-text">
                            {hintText}
                            {allowDelete && showResults && this.renderDelete()}
                        </div>
                        {(showResults || filterUsed) &&
                        <Form inline className="quick-search-form" onSubmit={e => e.preventDefault()}>
                            {allowDownload && showResults && this.renderDownload()}
                            {showResults && this.renderActionsBtns()}
                            {allowQuickSearch && !quickSearchOnTop && this.renderQuickSearch()}
                        </Form>
                        }
                    </Row>
                    {(showResults || filterUsed) && // Show only on results
                    <Row>
                        <Table>
                            <thead>
                            {this.renderHeader()}
                            </thead>
                            <tbody>
                            {items.map((item, i) => this.renderRow(item, i))}
                            </tbody>
                        </Table>
                        {(items.length === 0 && !filterUsed) &&
                        <div className="no-matching-data">
                            No matching data was found
                        </div>}
                    </Row>}
                    {showResults && allowPagination && // Show only on results
                    <Pagination
                        currentPage={page}
                        numPages={pages}
                        resultsPerPage={resultsPerPage}
                        showedItems={items.length}
                        totalItems={totalItems}
                        onChange={onPageChange}
                    />}
                </Col>
            </Row>
        );
    }
}

const columnPropType = PropTypes.shape({
    title: PropTypes.string.isRequired,
    field: PropTypes.string,
    id: PropTypes.string,
    render: PropTypes.func,
    className: PropTypes.string,
    sortable: PropTypes.bool,
    export: PropTypes.func,
});

DataGrid.propTypes = {
    data: PropTypes.arrayOf(PropTypes.object).isRequired,
    resultsPerPage: PropTypes.number,
    columns: PropTypes.arrayOf(columnPropType).isRequired,
    allowChecking: PropTypes.bool,
    allowQuickSearch: PropTypes.bool,
    allowDownload: PropTypes.bool,
    allowDelete: PropTypes.bool,
    downloadCSVfromBackend: PropTypes.bool,
    pageName: PropTypes.string,
    quickSearchPlaceholder: PropTypes.string,
    quickSearch: PropTypes.string,
    filterUsed: PropTypes.bool,
    onQuickSearchChange: PropTypes.func,
    onQuickSearchKeyPress: PropTypes.func,
    rowClassName: PropTypes.string,
    className: PropTypes.string,
    hintText: PropTypes.node,
    onSort: PropTypes.func,
    onAction: PropTypes.func,
    sortField: PropTypes.string,
    sortOrder: PropTypes.string,
    onDelete: PropTypes.func,
    page: PropTypes.number,
    total: PropTypes.number,
    onPageChange: PropTypes.func,
    quickSearchOnTop: PropTypes.bool,
    actions: PropTypes.arrayOf(PropTypes.shape({
        action: PropTypes.string.isRequired,
        title: PropTypes.string.isRequired,
    })),
    onUpdateData: PropTypes.func,
    csvFileName: PropTypes.string,
    allowSorting: PropTypes.bool,
    allowSelecting: PropTypes.bool,
    allowPagination: PropTypes.bool,
    selectedItem: PropTypes.string,
    onSelect: PropTypes.func,
    fullObjectDownload: PropTypes.bool,
    serverPagination: PropTypes.bool,
};

DataGrid.defaultProps = {
    resultsPerPage: 10,
    allowChecking: false,
    allowQuickSearch: false,
    allowDownload: false,
    allowSorting: true,
    allowSelecting: false,
    allowPagination: true,
    allowDelete: false,
    serverPagination: false,
    quickSearchPlaceholder: 'Search',
    csvFileName: 'peoples.csv',
    actions: [],
    quickSearch: '',
    filterUsed: false,
    rowClassName: '',
    className: '',
    hintText: '',
    sortField: '',
    sortOrder: '',
    page: 0,
    total: 0,
    onPageChange: () => {},
    onSort: () => {},
    onAction: () => {},
    onUpdateData: () => {},
    onDelete: () => {},
    onQuickSearchChange: () => {},
    onQuickSearchKeyPress: () => {},
};

export default DataGrid;