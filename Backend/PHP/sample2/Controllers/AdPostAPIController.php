<?php
namespace App\Http\Controllers\API;

use App\AdGenerator;
use App\AdPlatformAccount;
use App\AdPlatformAccountCat;
use App\AdPlatformCity;
use App\AdPlatformCityCat;
use App\AdPost;
use App\AdPostProfile;
use DB;
use Illuminate\Http\Request;
use Log;
use Route;

class AdPostAPIController extends BaseModelAPIController {
	public static function AddRoutes($url_root, $route_root) {
		Route::post($url_root.'/get_ad_for_posting/', ['uses'=>'API\AdPostAPIController@getAdForPosting', 'as'=>$route_root.'.get_ad_for_posting']);
		Route::post($url_root.'/{AdPost}/update', ['uses'=> 'API\AdPostAPIController@updateAd', 'as'=>$route_root.'.update_ad']);
		Route::post($url_root.'/{AdPost}/renew_account', ['uses'=>'API\AdPostAPIController@renewAccount', 'as'=>$route_root.'.renew_account']);
	}

	public function getAdForPosting(Request $request) {
        /**
         * @var \Illuminate\Database\Eloquent\Builder $q
         */
        $q = AdPostProfile::query()
            ->where('ad_post_profile.is_active', true)
            ->where(function($query){ $query->whereRaw('active_from <= NOW()')->orWhereNull('active_from');})
            ->where(function($query){ $query->whereRaw('active_to >= NOW()')->orWhereNull('active_to');})

            ->whereRaw(
                '(((`post_end_time` > `post_start_time` OR `post_start_time` IS NULL OR `post_end_time` IS NULL)
                   AND
                   (`post_start_time` <= NOW() OR `post_start_time` IS NULL)
                   AND
                   (`post_end_time` >= NOW() OR `post_end_time` IS NULL))
                  OR
                  (`post_start_time` > `post_end_time` AND `post_start_time` IS NOT NULL AND `post_end_time` IS NOT NULL
                   AND
                   (`post_start_time` <= NOW()
                    OR
                    `post_end_time` >= NOW()
                   )))')
            ->where('post_at_day_'.date('N'), '=', true)
			->whereRaw('(ad_post_profile.last_post_time <= ADDDATE(NOW(), INTERVAL -`post_interval` MINUTE) OR ad_post_profile.last_post_time IS NULL OR `post_interval` IS NULL)')
            ->select('ad_post_profile.*');
        if ( $request->has( 'platform' ) ) {
            $q->leftJoin( 'ad_platform', 'ad_post_profile.platform_id', '=', 'ad_platform.id' )
                ->where( 'ad_platform.code', '=', $request->input( 'platform' ) );
        }
        if ( $request->has( 'profile' ) ) {
            $q->where( 'ad_post_profile.id', '=', (int)$request->input( 'profile' ) );
        }
        $q->orderBy( 'last_post_time' );
        if ( config( 'cfg.poster.ad_per_package', 0 ) > 0 ) {
            $q->take( config( 'cfg.poster.ad_per_package', 0 ) );
        }
        /**
         * Mutex for concurrently execution
         */
        $key = ftok( __FILE__, 'p' );
        $sem = sem_get( $key );
        sem_acquire( $sem );
        $profiles = $q->get();
        $ids = [ ];
        foreach ( $profiles as $profile ) {
            $ids[] = $profile->id;
        }
        if ( $ids ) {
            AdPostProfile::whereIn( 'id', $ids )->update( [ 'last_post_time' => \Carbon\Carbon::now() ] );
        }
        sem_release( $sem );
//		return $profiles;
        $result = [ 'data' => [ ] ];
        /**
         * @var $profile AdPostProfile
         */
        foreach($profiles as $profile) {
            /**
             * @var AdPost[] $ads
             * @var AdPost $ad
             */
            $ads = AdPost::whereStatus(AdPost::$STATUS_FOR_PUBLISHING)
                ->whereProfileId($profile->id)
                ->take(1)
                ->get();
            foreach ($ads as $ad) {
                $ad->status = AdPost::$STATUS_PUBLISHING;
                $ad->save();
            }
            if ( ! count($ads) ) {
                $tags = [];
                foreach($profile->tags as $tag) {
                    $tags[] = $tag->id;
                }
                if ( ! $tags && ! config('cfg.poster.profile_no_tags_all', true) ) {
                    $account = [];
                } else {
                    $query = AdPlatformAccount::query()
                        ->leftJoin( 'ad_platform_account_cat', function ( $join ) use ( $profile ) {
                            $join->on( 'ad_platform_account.id', '=', 'ad_platform_account_cat.account_id' )
                                ->where( 'ad_platform_account_cat.category_id', '=', $profile->category_id );
                        } )
                        ->select( 'ad_platform_account.*', 'ad_platform_account_cat.id as cat_id' )
                        ->where( 'ad_platform_account.is_active', '=', true )
                        ->where( 'ad_platform_account.client_id', '=', $profile->client_id )
                        ->where( 'ad_platform_account.status', '=', 'active' )
                        ->where( 'ad_platform_account.platform_id', '=', $profile->platform_id )
                        ->where( 'ad_platform_account.city_id', '=', $profile->city_id )
                        ->where( function ( $query ) {
                            $query->whereRaw( 'ad_platform_account.num_ads < ad_platform_account.max_ads' )->orWhereNull( 'ad_platform_account.max_ads' );
                        } )
                        ->where( function ( $query ) {
                            $query->whereNull('ad_platform_account_cat.id')
                                ->orWhere(function ( $query ){
                                    $query->where('ad_platform_account_cat.is_active', '=', true)->where( function ( $query ) {
                                            $query->whereRaw( 'ad_platform_account_cat.num_ads < ad_platform_account_cat.max_ads' )->orWhereNull( 'ad_platform_account_cat.max_ads' );
                                        });
                                });
                        });

                    switch ( $profile->account_selection_strategy ) {
                        case( 'less_used' ):
                            $query->orderBy( 'ad_platform_account.num_ads', 'asc' )
                                ->orderBy( 'ad_platform_account_cat.updated_at' )
                                ->orderBy( 'ad_platform_account.created_at' );
                            break;
                        case( 'random' ):
                            $query->orderByRaw( 'RAND()' );
                            break;
                    }

                    if ( $tags ) {
                        $query->whereHas( 'tags', function ( $query ) use ( $tags ) {
                            $query->whereIn( 'ad_platform_account_tag.id', $tags );
                        } );
                    }
                    if ( $profile->as_agency != $profile->as_no_agency ) {
                        $query->whereIsAgency( $profile->as_agency );
                    }
                    $account = $query->first();
                }

                if ( !$account ) {
                    $profile->is_active = false;
                    $profile->fixLastPostTime();

                    Log::alert( "Profile $profile->id disabled because no accounts" );
                    //return [ 'error' => 'Accounts not available' ];
                    continue;
                }

                if ( $account->cat_id ) {
                    $cat = AdPlatformAccountCat::find( $account->cat_id );
                    DB::table( 'ad_platform_account_cat' )->where( 'id', '=',
                        $cat->id )->increment( 'num_ads' );
                } else {
                    if ( $el = AdPlatformCityCat::whereCategoryId( $profile->category_id )
                        ->whereCityId( $profile->city_id )
                        ->wherePlatformId( $profile->platform_id )
                        ->first() ) {
                        $max_ads = $el->max_ads;
                    } else {
                        $max_ads = null;
                    }

                    $cat = AdPlatformAccountCat::create( [
                        'is_active'     => true,
                        'account_id'    => $account->id,
                        'category_id'   => $profile->category_id,
                        'num_ads'       => 1,
                        'max_ads'       => $max_ads
                    ] );
                }

                DB::table( 'ad_platform_account' )
                    ->where( 'id', '=', $account->id )
                    ->increment( 'num_ads' );

                DB::table( 'ad_platform_account' )
                    ->where( 'id', '=', $account->id )
                    ->whereNotNull( 'max_ads' )
                    ->whereRaw( 'max_ads = num_ads' )
                    ->update( [ 'status' => 'used' ] );

                $opts = [
                    'city'       => $profile->city,
                    'platform'   => $profile->platform,
                    'client'     => $profile->client,
                    'profile'    => $profile,
                    'phones'     => preg_split( "/[\r\n]+/", $profile->phones ),
                    'account'    => $account,
                    'category'   => $profile->category,
                ];
                $generator_class = '\\App\\AdGenerators\\' . studly_case($profile->category->code);


                /**
                 * @var \App\AdGenerators\BaseGenerator $adgen
                 */
                $adgen = new $generator_class( $opts );
                $addata = $adgen->getAdData();
                $addata[ 'status' ] = AdPost::$STATUS_PUBLISHING;
                if ($profile->platform->code == 'vk') {
                    /**
                     * @var AdVKGroup $vkgroup
                     */
                    foreach($profile->vkgroups()->whereIsActive(true)->get() as $vkgroup) {
                        $addata['extra'] = ['group'=>$vkgroup->link];
                        $ads[] = AdPost::create( $addata );
                    }
                } else {
                    $ads[] = AdPost::create( $addata );
                }
            }

            foreach ($ads as $ad) {
                $el = $ad->toArray();
                $el[ 'city' ] = $profile->city->toArray();
                $el[ 'city' ][ 'region' ] = $profile->city->region->toArray();
                $el[ 'account' ] = $ad->account->toArray();
                $el[ 'district' ] = $ad->district->toArray();
                $el[ 'profile' ] = $profile;
                $el[ 'category' ] = $profile->category;
                if ( $extra = AdPlatformCity::whereCityId( $el[ 'city_id' ] )->wherePlatformId( $el[ 'platform_id' ] )->first() ) {
                    $el[ 'city' ][ 'extra' ] = $extra->extra;
                }
                if ( $ad->rr_addr_id ) {
                    $el[ 'rr_addr' ] = $ad->rr_addr->toArray();
                }
                $result[ 'data' ][ ] = $el;
            }
        }
        $result[ 'status' ] = 'success';
        $result[ 'code' ] = '200';
        return $result;
	}

    /**
     * @param AdPost $element
     */
    public function updateAd(Request $request, $element) {
        $status = $request->input('status');
        switch($status) {
            case('published'):
                if ($request->has('link')) {
                    $element->link = $request->input('link');
                }
                $element->setPublished();
                return [ 'code' => 200, 'status' => 'success', 'data' => $element->toArray() ];
                break;

            case('no_published'):
                $element->setNotPublished();
                return [ 'code' => 200, 'status' => 'success', 'data' => $element->toArray() ];
                break;

        }
    }

    /**
     * @param AdPost $element
     */
    public function renewAccount(AdPost $element) {
        $account = AdPlatformAccount::whereIsActive( true )
            ->whereClientId( $element->client_id )
            ->whereStatus( 'active' )
            ->wherePlatformId( $element->platform_id )
            ->whereCityId( $element->city_id )
            ->where('id', '!=', $element->account_id)
            ->where( function ( $query ) {
                $query->whereRaw( 'num_ads < max_ads' )->orWhereNull( 'max_ads' );
            } )
            ->OrderByRaw( 'RAND()' )
            ->first();
        if ( $account ) {
            DB::table( 'ad_platform_account' )->where( 'id', '=',
                $account->id )->update( [ 'num_ads' => DB::raw( 'num_ads+1' ) ] );
            DB::table( 'ad_platform_account' )
                ->where( 'id', '=', $account->id )
                ->whereNotNull( 'max_ads' )
                ->whereRaw( 'max_ads = num_ads' )
                ->update( [ 'status' => 'used' ] );
            $element->account_id = $account->id;
            $element->save();
            return [ 'data' => $account ];
        } else {
            $element->profile->is_active = false;
            $element->profile->save();
            Log::alert("Profile $element->profile_id disabled because no accounts");
            return [ 'data' => [] ];
        }
    }
}