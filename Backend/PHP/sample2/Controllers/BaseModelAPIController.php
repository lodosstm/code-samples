<?php
namespace App\Http\Controllers\API;

use Illuminate\Http\Request;
use Validator;

class BaseModelAPIController extends BaseController {

	protected $meta = false;
	protected $base_route;

	public function getMeta() {
		if ( $this->meta ) {
			return $this->meta;
		}
		$route = \Route::getCurrentRoute()->getName();
		$this->base_route = $route = substr( $route, 4, strrpos( $route, '.' ) - 4 );
		return $this->meta = config( 'model' )[ $route ];
	}

	/**
	 * Display a listing of the resource.
	 *
	 * @return Response
	 */
	public function index( Request $request ) {
		$meta = $this->getMeta();
		$model = $meta[ 'model' ];
		$res = array();
		/**
		 * @var \Illuminate\Database\Eloquent\Builder $query
		 */

		$query = $model::query();
		if ( $request->has( 'order' ) ) {
			foreach ( $request->input( 'order' ) as $field => $dir ) {
				$query->orderBy( $field, $dir );
			}
		}

		if ( $request->has( 'filter' ) ) {
			$scope = Str::Camel( $request->input( 'filter' ) );
			$method = Str::Camel( 'scope_' . $request->input( 'filter' ) );
			if ( method_exists( $model, $method ) ) {
				$query->$scope();
			} else {
				return [ 'error' => 'Unknown filter' ];
			}
		}

		if ( $request->has( 'take' ) ) {
			$query->take( $request->input( 'take' ) );
		}

		if ( $request->has( 'where' ) ) {
			foreach ( $request->input( 'where' ) as $item ) {
				$query->where( $item[ 'col' ], $item[ 'op' ], $item[ 'val' ], $item[ 'bool' ] );
			}
		}
		$res[ 'status' ] = 'success';
		$res[ 'code' ] = 200;
		$res[ 'data' ] = $query->get();
		return $res;
	}

	/**
	 * Display the specified resource.
	 *
	 * @param  int $id
	 *
	 * @return Response
	 */
	public function show( Request $request, $item ) {
		$with_relations = [ ];
		$result = $item->toArray();
		if ( $request->has( 'with' ) ) {
			$with = $request->get( 'with' );
			if ( is_string( $with ) ) {
				$with = explode( '|', $with );
			}
			$with_relations = $with;
			foreach ( $with as $relation ) {
				$result[ $relation ] = $item->$relation;
			}
		}

		return [ 'status' => 'success', 'code' => 200, "data" => $result ];
	}

	/**
	 * Store a newly created resource in storage.
	 *
	 * @return Response
	 */
	public function store( Request $request ) {
		$meta       = $this->getMeta();
		$model      = $meta[ 'model' ];
		$validation = Validator::make( $request->input(), $model::$rules );
		if ( $validation->passes() ) {
			$item = $model::create( $request->input() );
			return response( [ 'status' => 'success', 'code' => 201, 'data' => $item ], 201,
					[ 'Location' => route( 'api_' . $this->base_route . '.show', $item->id ) ] );
		} else {
			return response( [ 'status' => 'error', 'code' => 422, 'error' => $validation->errors() ], 422 );
		}
	}


	/**
	 * Update the specified resource in storage.
	 *
	 * @param  int $id
	 *
	 * @return Response
	 */
	public function update(Request $request, $item ) {
		$model = get_class( $item );
		if ( isset( $model::$rules_edit ) ) {
			$rules = $model::$rules_edit;
		} else {
			$rules = $model::$rules;
		}
		foreach ( $rules as $key=>&$rule ) {
			if ($request->has($key)) {
				if ( substr( $rule, -1, 1 ) == ',' ) {
					$rule .= $item->id;
				}
			} else {
				unset( $rules[ $key ] );
			}
		}
		$validation = Validator::make( $request->input(), $rules );
		if ( $validation->passes() ) {
			if ( $item->update( $request->input() ) ) {
				return [ 'status' => 'success', 'code' => 200, 'data' => $item ];
			} else {
				return response( [ 'status' => 'fail', 'code' => 500, 'error' => [ 'Can`t update' ] ], 500 );
			}
		} else {
			$errors = $validation->errors()->toArray();
			foreach ($errors as $code=>&$message) {
				$message = str_replace( '%attribute%', '"' . $model::getFieldLabel($code) . '"', $message );
			}
			return response( [ 'status' => 'error', 'code' => 422, 'error' => $errors ], 422 );
		}
	}


	/**
	 * Remove the specified resource from storage.
	 *
	 * @param  int $id
	 *
	 * @return Response
	 */
	public function destroy( Request $request, $item ) {
		$item->delete();
		return [ 'status' => 'success' ];
	}


	public function rootOptions( Request $request ) {
		$headers = [
				'Allow' => 'HEAD,GET,POST,OPTIONS',
		];
		//config('api_application')
		return response( [ 'status' => 'success', 'code' => 200 ], 200, $headers );
	}

	public function itemOptions( Request $request ) {
		$headers = [
				'Allow' => 'HEAD,GET,PUT,POST,DELETE,OPTIONS',
		];
		//config('api_application')
		return response( [ 'status' => 'success', 'code' => 200 ], 200, $headers );
	}
}
