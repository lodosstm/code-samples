<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use Debugbar;

class BaseController extends Controller {

	public function __construct() {
		$this->middleware( 'auth.api' );
		Debugbar::disable();
	}

	public static function AddRoutes($url_root, $route_root) {

	}

}
