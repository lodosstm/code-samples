import { Component, Input, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { MAT_DIALOG_DATA, MatDialog, MatDialogRef } from '@angular/material';
import { DateTimeAdapter } from 'ng-pick-datetime';
import * as moment from 'moment';
import * as _ from 'lodash';
import { IDateNames, IDay, IEvent, IFilter, IWarningState } from '../events-helpers/events.interfaces';
import { EventsService } from '../events-helpers/events.service';
import { EventsModalComponent } from './events-modal.component';

@Component({
	selector: 'events-calendar',
	templateUrl: './events-calendar.component.html'
})
export class EventsCalendarComponent implements OnInit {
	public link;
	public days: Array<IDay>;
	public mobileDays: Array<Array<IDay>>;
	public newStartEventsList;
	public dateNames: IDateNames;
	public year: number;
	protected tmpWarningState: any;
	public today: number;
	public curMonth;
	public locale = 'nl-NL';
	public currentLocation;
	public offsetState: Map<string, IEvent | boolean>;

	ngOnInit(): void {
		this.locale = this.currentLocation === 'mons' ? 'fr-FR' : this.locale;
		this.dateTimeAdapter.setLocale(this.locale);
		this.eventsService.setLocationAndFormConfig(this.currentLocation);
		this.init();
	}
	public openDialog(day): void {
		const dialogRef = this.dialog.open(EventsModalComponent, {
			width: '500px',
			data: {
				day,
				link: this.link
			},
		});
	}
	/**
	 * @description warning side-effect
	 */
	public getVOffsetClass(day: IDay, event?: IEvent): string {
		let vOffsetClass = '';
		const key = moment(day.date)
			.format('DD_MM_YYYY');
		if (moment(day.date)
			.isoWeekday() === 1) {
			if (!this.offsetState.get('isMonday')) {
				this.offsetState.clear();
			}
			this.offsetState.set('isMonday', true);
		} else {
			this.offsetState.set('isMonday', false);
		}
		this.offsetState.forEach((v, k) => {
			if (k !== key) {
				if (typeof (v) === 'object') {
					if (!v.end || moment(v.end)
						.isBefore(day.date)) {
						this.offsetState.delete(k);
					}
				}
			}
		});
		vOffsetClass = `location-calendar__event_vertical-offset-${this.offsetState.size - 1}`;
		if (event) {
			this.offsetState.set(
				key,
				event
			);
		}

		return vOffsetClass;
	}
	/**
	 * @description warning side-effect
	 */
	public getVOffsetClassOld(day: IDay, event?: IEvent): string {
		let vOffsetClass = '';

		this.offsetState.delete(
			moment(day.date)
				.format('DD_MM_YYYY')
		);
		if (
			moment(day.date)
				.isoWeekday() === 1
		) {
			this.offsetState.clear();
		}
		vOffsetClass = `location-calendar__event_vertical-offset-${this.offsetState.size}`;
		if (day.multiple) {
			const key = moment(event.end || day.date)
				.format('DD_MM_YYYY');
			this.offsetState.set(key, event);
		}

		return vOffsetClass;
	}
	public init(date?: Date): void {
		if (!date) {
			date = new Date();
		}
		this.offsetState = new Map();
		this.days = this.eventsService.getDays(date);
		this.mobileDays = this.eventsService.getDaysForMobile();
		this.curMonth = this.eventsService.getCurrentMoment()
			.toDate()
			.getMonth();
		this._setDateNames();
		this._setYear();
		this.days = this.days.map((day: IDay, i, arr) => {
			const tmpDay = _.cloneDeep(day);
			tmpDay.class = this.getColClasses(tmpDay, i, arr);
			if (tmpDay.events) {
				if (!_.isEmpty(tmpDay.events)) {
					tmpDay.events.forEach(event => {
						event.class = this.getEventClasses(tmpDay, event);
					});
				} else {
					this.getVOffsetClass(tmpDay);
				}
			}
			if (tmpDay.warn) {
				tmpDay.warn.class = this.getWarnClasses(tmpDay);
			}

			return tmpDay;
		});
	}
	constructor(
		public eventsService: EventsService,
		public dateTimeAdapter: DateTimeAdapter<any>,
		public dialog: MatDialog, public router: Router,
		public activatedRoute: ActivatedRoute
	) {
		this.currentLocation = activatedRoute.snapshot.url[0].path;
		this.link = activatedRoute.snapshot.url.join('/');
	}
	protected _setDateNames(): void {
		this.dateNames = {
			week: this._getDaysOfWeek('long'),
			weekShort: this._getDaysOfWeek('short'),
			months: this._getMonths()
		};
	}
	protected _setMultipleEvents(day: IDay, event: IEvent): void {
		if (event.end) {
			let isFound = false;
			const eventDiff: number = this._diff(event.end, day.date);
			const countOffset = this._getOffset(day);
			const newStart = this._clone(day.date);
			newStart.setDate(newStart.getDate() + (7 - countOffset));
			const needOffset = (7 - countOffset - eventDiff) < 0;
			const eventCopy = {
				text: event.text,
				type: event.type,
				end: this._clone(event.end),
				link: event.link
			};
			if (needOffset) {
				this.days.forEach((elDay: IDay) => {
					if (this.dateTimeAdapter.isSameDay(elDay.date, newStart)) {
						isFound = true;
						if (!this.isSet(elDay.events)) {
							elDay.events = [];
						}
						elDay.events.push(eventCopy);
					}
				});
				if (!isFound) {
					this.days.push({
						date: newStart,
						multiple: true,
						events: [eventCopy]
					});
				}
				if (!this.isSet(this.newStartEventsList)) {
					this.newStartEventsList = [];
				}
				this.newStartEventsList.push(eventCopy);
			}
		}
	}
	protected _getDaysOfWeek(type: 'long' | 'short'): Array<string> {
		const daysOfWeek = this.dateTimeAdapter.getDayOfWeekNames(type);
		daysOfWeek.push(daysOfWeek.shift());

		return daysOfWeek;
	}
	protected _getMonths(): Array<string> {
		return this.dateTimeAdapter.getMonthNames('long');
	}
	protected _setYear(): void {
		this.year = this.eventsService.getCurrentMoment()
			.toDate()
			.getFullYear();
	}
	public getColClasses(day: IDay, i, arr): any {
		if (typeof (day.warn) !== 'undefined') {
			const warnDiff: number = this._diff(day.warn.end, day.date);
			if (warnDiff > 1) {
				this.tmpWarningState = undefined;
				this.tmpWarningState = { date: this._clone(day.date), counter: warnDiff, text: day.warn.text };
			}
		}
		if (this._isMultipleWarn(day)) {
			day.warn = {
				text: this.tmpWarningState.text,
				end: this._clone(day.date)
			};
			this.tmpWarningState.counter--;
		}

		return {
			'location-calendar__col_today': ((day.date.getDate() === this.today) && (day.date.getMonth() === new Date().getMonth())),
			'location-calendar__day_notcur': (day.date.getMonth() !== this.eventsService.getCurrentMoment()
				.toDate()
				.getMonth()),
			'location-calendar__col_warn': (day.warn)
		};
	}
	protected _clone(date: Date): Date {
		return new Date(date.getTime());
	}
	protected _isMultipleWarn(day): boolean {
		return (
			this.isSet(this.tmpWarningState) &&
			day.date.getDate() !== this.tmpWarningState.date.getDate() &&
			this.tmpWarningState.counter > 1
		);
	}
	public isSet(data): boolean {
		return typeof (data) !== 'undefined';
	}
	public getWarnClasses(day: IDay): any {
		const warnDiff: number = this._diff(day.warn.end, day.date);
		const className = `location-calendar__warn_${warnDiff}`;
		const tmpDate = this._clone(this.eventsService.getCurrentMoment()
			.toDate());
		let needOffset = false;
		tmpDate.setDate(day.date.getDate());
		const diff = tmpDate.getDay();
		if ((diff - 1 + warnDiff) > 7) {
			needOffset = true;
		}

		return {
			[className]: needOffset
		};
	}
	protected _diff(dateEnd, dateStart): number {
		return this.dateTimeAdapter.differenceInCalendarDays(dateEnd, dateStart) + 1;
	}
	public getEventClasses(day: IDay, event: IEvent): any {
		const tmpDay = _.cloneDeep(day);
		const tmpEvent = _.cloneDeep(event);
		const dayMoment = moment(tmpDay.date);
		const needStart = dayMoment.isoWeekday() === 1;
		const eventDiff: number = this._diff(tmpEvent.end, tmpDay.date);
		const name = `location-calendar__event_multiple-${eventDiff}`;
		const countOffset = this._getOffset(tmpDay);
		const nameOffset = `location-calendar__event_multiple-offset-${countOffset}`;
		const needOffset = (7 - countOffset - eventDiff) < 0;
		const verticalOffsetClass = this.getVOffsetClass(tmpDay, tmpEvent);

		return {
			'location-calendar__event_multiple': (tmpDay.multiple),
			[name]: (tmpDay.multiple),
			[nameOffset]: needOffset,
			'location-calendar__event_multiple-start': needStart,
			[verticalOffsetClass]: true
		};
	}
	protected _getDates(startDate: Date, stopDate: Date): Array<Date> {
		const dateArray = [];
		let currentDate = startDate;
		while (currentDate <= stopDate) {
			dateArray.push(new Date(currentDate));
			currentDate = this.dateTimeAdapter.addCalendarDays(currentDate, 1);
		}

		return dateArray;
	}
	protected _getOffset(day: IDay): number {
		let offset: number;
		const tmpMoment = moment(day.date);
		offset = tmpMoment.isoWeekday() - 1;

		return offset;
	}

	public nextMonth(): void {
		const currentMoment = this.eventsService.getCurrentMoment();
		this.init(currentMoment.add(1, 'M')
			.toDate());
	}
	public prevMonth(): void {
		const currentMoment = this.eventsService.getCurrentMoment();
		this.init(currentMoment.add(-1, 'M')
			.toDate());
	}
}
