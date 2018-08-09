<?php

namespace Api\v1;

use Swagger\Annotations as SWG;

/**
 * @SWG\Resource(
 * 	apiVersion="1.0",
 *	resourcePath="/events",
 *	basePath="http://test.dev/api/v1/events/",
 *	description="Event API routes. ",
 *	produces="['application/json']"
 * )
 */

class EventController extends MainController {

	private $rules = [
		'events' => [
			'page' => 'required|integer',
		],
		'event' => [
			'id' => 'required',
		]
	];

	/**
	 * @SWG\Api(
	 * 	path="/",
	 *      @SWG\Operation(
	 *      	method="GET",
	 *      	summary="Get all user events",
	 *			type="EventModel",
	 *		@SWG\Parameter(
	 *			name="page",
	 *			description="Number of event page to fetch",
	 *			paramType="query",
	 *      		required=true,
	 *      		allowMultiple=false,
	 *      		type="integer"
	 *      	),
	 *		@SWG\ResponseMessage(code=200, message="List of events"),
	 *		@SWG\ResponseMessage(code=404, message="Events not found")
	 *   )
	 * )
	 */
	public function index() {
		$inputs = \Input::only('page');

		$validator = $this->validate($inputs, $this->rules['events']);

		if($validator->fails()) {
			return $this->response($validator->messages(), 400);
		}

		$page = \Input::get('page', 1);
		$per_page = \Input::only('per_page');

		$events = $this->user->events->merge($this->user->accessibleEvents)->sortByDesc('created_at')
			->slice($per_page * max( array( 0, $page-1) ), $per_page)
			->sortByDesc("id")
			->transform(function ($item) {
				$item->accepted_count = $item->acceptsCount();
				$item->declined_count = $item->declinesCount();
				unset($item->submissions);
				return $item;
			})
			->all();

		return $this->response($events);
	}

	/**
	 * @SWG\Api(
	 * 	path="{id}",
	 *      @SWG\Operation(
	 *      	method="GET",
	 *   		summary="Displays an event",
	 *			type="EventModel",
	 *		@SWG\Parameter(
	 *			name="id",
	 *			description="id of event to fetch",
	 *			paramType="path",
	 *      		required=true,
	 *      		allowMultiple=false,
	 *      		type="integer"
	 *      	),
	 *		@SWG\ResponseMessage(code=200, message="One event"),
	 *		@SWG\ResponseMessage(code=404, message="Event not found")
	 * 	)
	 * )
	 */
	public function show() {
		$this->event->accepted_count = $this->event->acceptsCount();
		$this->event->declined_count = $this->event->declinesCount();
		$this->event->secondary_events = $this->event->secondaryEvents()->get()
			->transform(function ($secondary_event) {
				$secondary_event->accepted_count = $secondary_event->acceptedCount();
				$secondary_event->declined_count = $secondary_event->declinedCount();
				return $secondary_event;
			})
			->all();

		return $this->response($this->event);

	}

	/**
	 * @SWG\Api(
	 * 	path="search/{query}",
	 *      @SWG\Operation(
	 *      	method="GET",
	 *      	summary="Search events",
	 *			type="EventModel",
	 *		@SWG\Parameter(
	 *			name="query",
	 *			description="Search query with event name",
	 *			paramType="path",
	 *      		required=true,
	 *      		allowMultiple=false,
	 *      		type="string"
	 *      	),
	 *		@SWG\ResponseMessage(code=200, message="List of events"),
	 *		@SWG\ResponseMessage(code=404, message="Events not found")
	 * 	)
	 * )
	 */
	public function search() 
	{
		$query = \Input::get('query');

		if(is_null($query))
		{
			return $this->response("Empty query for search", 400);
		}

		$all_user_events = $this->user->events->merge($this->user->accessibleEvents)->lists('id');

		if(count($all_user_events) <= 0) {
			return $this->response("You did not create events yet", 400);
		}

		$events = \EventModel::where('heading', 'LIKE', '%' . $query . '%')
			->whereIn('id', $all_user_events)
			->orderBy('id', 'desc')
			->get();

		$events_with_info = [];

		foreach ($events as $event) {
			$event->accepted_count = $event->acceptsCount();
			$event->declined_count = $event->declinesCount();
			$event->secondary_events = $event->secondaryEvents()->get()
				->transform(function ($secondary_event) {
					$secondary_event->accepted_count = $secondary_event->acceptedCount();
					$secondary_event->declined_count = $secondary_event->declinedCount();
					return $secondary_event;
				})
				->all();
			array_push($events_with_info, $event);
		}

		return $this->response($events_with_info, 200);
	}

}