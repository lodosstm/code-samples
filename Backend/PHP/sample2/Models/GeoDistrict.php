<?php

namespace App;

class GeoDistrict extends BaseModel {
	protected $table = 'geo_district';

	/**
	 * @var string Корневой маршрут. Заполняется при инициализации сайта и служит для связывания с метаданными.
	 */
	protected static $route = '';
	protected static $list_column = 'title';

	public static $rules = array(
			'code' => 'required',
			'name' => 'required',
			'city_id' => 'required',
			'platform_id' => 'required',
	);

    protected $fillable = [ 'is_active', 'code', 'name', 'city_id', 'platform_id', 'original_id', 'category_id' ];

	protected $guarded = [
			'id',
			'created_at',
			'updated_at',
	];

	public function city() {
		return $this->belongsTo( 'App\GeoCity', 'city_id' );
	}

    public function platform() {
        return $this->belongsTo( 'App\AdPlatform', 'platform_id' );
    }

	public function category() {
		return $this->belongsTo( 'App\AdCategory', 'category_id' );
	}

	public function streets() {
		return $this->hasMany('App\GeoDistrictStreet', 'district_id');
	}

	public function rr_addrs() {
		return $this->hasMany('App\GeoRRAddr', 'district_id');
	}

	/**
	 * @return \Illuminate\Database\Eloquent\Builder
	 */
	public static function getListQuery() {
		$query = parent::getListQuery();
		$query->with( [ 'city', 'platform', 'category' ] );
		return $query;
	}

	public function getTitleAttribute() {
		return $this->city->name . ' - ' . $this->name . ' (' . $this->platform->name .' - '.$this->category->name.')';
	}
}