<?php

namespace App;

class GeoCity extends BaseModel {
	protected $table = 'geo_city';

	/**
	 * @var string Корневой маршрут. Заполняется при инициализации сайта и служит для связывания с метаданными.
	 */
	protected static $route = '';

	public static $rules = array(
			'code' => 'required|unique:geo_city',
			'name' => 'required',
	);
	public static $rules_edit = array(
			'code' => 'required|unique:geo_city,code,',
			'name' => 'required',
	);

	protected $fillable = [
			'code', 'name', 'is_active', 'region_id', 'price_1r_min', 'price_1r_max', 'price_2r_min', 'price_2r_max',
			'price_room_min', 'price_room_max'
	];

    public static $nullable = [ 'price_1r_min', 'price_1r_max', 'price_2r_min', 'price_2r_max', 'price_room_min', 'price_room_max' ];

	protected $guarded = [
			'id',
			'created_at',
			'updated_at',
	];

	public function streets() {
		return $this->hasMany( 'App\GeoStreet', 'city_id' );
	}

	public function region() {
		return $this->belongsTo( 'App\GeoRegion', 'region_id' );
	}

	public function districts() {
		return $this->hasMany( 'App\GeoDistrict', 'city_id' );
	}
}