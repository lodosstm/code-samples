<?php

namespace App\Http\Middleware;

use App\ApiApplication;
use Closure;

class AuthAPI {
	/**
	 * Handle an incoming request.
	 *
	 * @param  \Illuminate\Http\Request $request
	 * @param  \Closure                 $next
	 *
	 * @return mixed
	 */
	public function handle( $request, Closure $next ) {
		/**
		 * @var ApiApplication $app
		 * @var Request $request
		 */
		$token = false;
		if ($request->header('X-Auth-Token')) {
			$token = $request->header('X-Auth-Token');
		} elseif($request->has('_token')) {
			$token = $request->get( '_token' );
		}

		if (!$token || (!$app = ApiApplication::whereToken($token)
						->where(function($query){ $query->where('active_from', '<=', date('Y-m-d'))->orWhereNull('active_from');})
						->where(function($query){ $query->where('active_to', '>=', date('Y-m-d'))->orWhereNull('active_to');})
						->first())) {
			return response( [ 'error' => 'Unauthorized' ], 401 );
		}

		if (!$app->is_active) {
			return response( [ 'error' => 'Unauthorized' ], 401 );
		}
		$model=$request->route()->getName();
		$pos = strpos($model, '_');
		$model = substr($model, $pos+1, strrpos($model, '.') - $pos-1);
		if (!(isset($app->acl['models']) && array_search($model, $app->acl['models']) !== false)) {
			return response( [ 'error' => 'Access denied' ], 403 );
		}
		config(['api_application' => $app]);

		return $next( $request );
	}
}
