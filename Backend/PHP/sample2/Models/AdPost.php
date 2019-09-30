<?php

namespace App;

class AdPost extends BaseModel {

	/**
	 * The database table used by the model.
	 *
	 * @var string
	 */
	protected $table = 'ad_post';

	/**
	 * @var string Корневой маршрут. Заполняется при инициализации сайта и служит для связывания с метаданными.
	 */
	protected static $route = '';

    public static $STATUS_NEW = 'new';
    public static $STATUS_FOR_PUBLISHING = 'for_publishing';
    public static $STATUS_PUBLISHING = 'publishing';
    public static $STATUS_PUBLISHED = 'published';
    public static $STATUS_UNPUBLISHED = 'unpublished';

	protected $fillable = [ 'status', 'client_id', 'city_id', 'platform_id', 'phone', 'rooms', 'floor', 'floor_of',
			'house_type', 'square', 'address', 'text', 'text_hash', 'attrs', 'link', 'price', 'district_id', 'account_id',
			'publish_start_at', 'publish_finish_at', 'contact', 'profile_id', 'extra', 'views', 'category_id', 'rr_addr_id' ];

    protected static $nullable = [ 'link', 'profile_id', 'category_id' ];
	public static $rules = array(
			'city_id'     => 'required|integer',
			'status'      => 'required',
			'client_id'   => 'required|integer',
			'district_id' => 'required|integer',
			'platform_id' => 'required|integer',
			'account_id'  => 'required|integer',
			'category_id' => 'integer'
	);

	protected $guarded = [
			'id',
			'created_at',
			'updated_at',
	];

	public function getDates() {
		return [ 'created_at', 'updated_at', 'publish_start_at', 'publish_finish_at' ];
	}

	public function city() {
		return $this->belongsTo( 'App\GeoCity', 'city_id' );
	}

	public function district() {
		return $this->belongsTo( 'App\GeoDistrict', 'district_id' );
	}

	public function account() {
		return $this->belongsTo( 'App\AdPlatformAccount', 'account_id' );
	}

	public function client() {
		return $this->belongsTo( 'App\Client', 'client_id' );
	}

	public function platform() {
		return $this->belongsTo( 'App\AdPlatform', 'platform_id' );
	}

    public function profile() {
        return $this->belongsTo( 'App\AdPostProfile', 'profile_id' );
    }

	public function category() {
		return $this->belongsTo( 'App\AdCategory', 'category_id' );
	}

	public function rr_addr() {
		return $this->belongsTo( 'App\GeoRRAddr', 'rr_addr_id' );
	}

	public function setTextAttribute( $value ) {
		$this->attributes[ 'text' ]      = $value;
		$this->attributes[ 'text_hash' ] = md5( $value );
	}
	protected function getAttrsAttribute( $value ) {
		return json_decode( $value, 1 );
	}

	protected function setAttrsAttribute( $value ) {
		$this->attributes[ 'attrs' ] = json_encode( $value );
	}

    protected function getExtraAttribute( $value ) {
        return json_decode( $value, true );
    }

    protected function setExtraAttribute( $value ) {
        $this->attributes[ 'extra' ] = json_encode( $value );
    }
	/*public static function canEdit( $el = NULL ) {
		return false;
	}*/

	public static function canDelete( $el = NULL ) {
		return true;
	}

    public function getNameAttribute() {
        return '#' . $this->id . ' - ' . $this->platform->name;
    }

	/**
	 * set "for_publishing" status
	 * @return $this
	 */
	public function setNotPublished() {
		$this->status = AdPost::$STATUS_FOR_PUBLISHING;
		$this->profile->fixLastPostTime();
		$this->save();
		return $this;
	}

	/**
	 * set "published" status
	 * @return $this
	 */
	public function setPublished() {
		$this->status = AdPost::$STATUS_PUBLISHED;
		$this->publish_start_at = \Carbon\Carbon::now();
		$this->save();
		return $this;
	}
}
