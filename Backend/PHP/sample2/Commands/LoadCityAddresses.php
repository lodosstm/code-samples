<?php
namespace App\Console\Commands;

use App\AdCategory;
use App\AdPlatform;
use App\GeoCity;
use App\GeoDistrict;
use App\GeoDistrictStreet;
use Illuminate\Console\Command;

class LoadCityAddresses extends Command {

    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'load:addresses {cat} {file}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description.';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct() {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle() {
        $category = AdCategory::whereCode( $this->argument( 'cat' ) )->first();
        $file = file( $this->argument( 'file' ) );
        $platforms = [ ];
        foreach ( AdPlatform::all() as $item ) {
            $platforms[ $item->code ] = $item;
        }
        $cities = [ ];
        foreach ( GeoCity::all() as $item ) {
            $cities[ $item->name ] = $item;
        }

        $districts = [ ];

        foreach ( $file as $line ) {
            try {
                @list($platform_code, $city_name, $district_name, $street, $houses) = explode(';', $line);
                $platform_code = trim($platform_code);
                $city_name = trim($city_name);
                $district_name = trim($district_name);
                $street = trim($street);
                $houses = trim($houses);
                $platform = $platforms[$platform_code];
                $city = $cities[$city_name];
                /**
                 * @var GeoDistrict $district
                 * @var GeoCity $city
                 */
                if (!isset($districts[$city->id])) {
                    foreach (GeoDistrict::whereCityId($city->id)->wherePlatformId($platform->id)->whereCategoryId($category->id)->get() as $district) {
                        $districts[$city->id][$district->name] = $district;
                    }
                }

                if (isset($districts[$city->id][$district_name])) {
                    $district = $districts[$city->id][$district_name];
                } else {
                    // Create an district
                    $district = GeoDistrict::create([
                        'is_active' => true,
                        'code' => $district_name,
                        'name' => $district_name,
                        'city_id' => $city->id,
                        'platform_id' => $platform->id
                    ]);
                    $districts[$city->id][$district_name] = $district;
                }

                if ($el = GeoDistrictStreet::whereDistrictId($district->id)->whereName($street)->first()) {
                    if ($el->houses != $houses) {
                        $el->houses = $houses;
                        $el->save();
                    }
                } else {
                    GeoDistrictStreet::create([
                        'is_active' => true,
                        'name' => $street,
                        'district_id' => $district->id,
                        'houses' => $houses,
                    ]);
                }
            } catch (Exception $e) {
                $this->error($e->getMessage());
            }
        }

    }
}
