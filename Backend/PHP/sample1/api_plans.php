<?php


  /**
   *
   * REST API
   * 
   *
   */
  class API_Plans_Controller extends Base_Controller {

    public $restful = true;
    private $aConfig;
    private $iUserId;


    public function __construct() {

      parent::__construct();
      $this->aConfig = Laravel\Config::get( 'application.oauth2' );
      $this->iUserId = Session::get( 'userdata.user.id' );

    }

    public function get_index($id = null) {

      if(!$id) {

        return Response::json(Plan::get_allPlans(Input::get('limit'), Input::get('offset')));

      } else {

        $aPlan = Plan::get_byId( $id );

        if( $aPlan AND $aPlan['error'] == '' ) {

          $oShare = Plan_Share::where( 'plan_id', '=', $id )
          ->where( 'user_id', '=', $this->iUserId )->first( array('permission') );

          if( $oShare ) {

            $aPlan['plan']['permission'] = $oShare->permission;

          }

        }
        
        if($aPlan['plan']['user_id'] != $this->iUserId) {
          $aPlan['plan']['sharedWithMe'] = 1;
        } else {
          $aPlan['plan']['sharedWithMe'] = 0;
        }


        return Response::json( $aPlan );
      }
    }

    public function get_by_user_id($iUserId = null)
    {
      return Response::json(Plan::get_byUserId($iUserId));
    }

    public function get_weeks($iPlanId = null)
    {
      return Response::json(Plan_Week::get_byPlanId($iPlanId));
    }

    public function put_weeks($id = null)
    {
      return Response::json(Plan_Week::update_byId($id));
    }

    public function get_count_similar_name()
    {
      return Response::json(Plan::get_countSimilarName());
    }

    public function post_copy_by_id($iPlanId = null)
    {
      if( !Plan_Share::checkPermissions( $this->iUserId, $iPlanId ) ) {

        $aResponse['error'] = 'access_forbidden';
        $aResponse['error_description'] = "You don’t have permission to do this.";
        return Response::json( $aResponse );

      }
      return Response::json(Plan::copy_byPlanId($iPlanId));
    }

    public function post_index()
    {
      return Response::json(Plan::createPlan());
    }

    public function put_index($id = null)
    {
      $iPlanId = $id;
      $aInputData = (array)Input::json()->plan;

      if(isset($aInputData['sharedWithMe'])) {
        unset($aInputData['sharedWithMe']);
      }

      if( $aInputData AND $aInputData['id'] ) {

        if( $aInputData['id'] != $id ) {

          $iPlanId = $aInputData['id'];

        }

      } 

      if( !Plan_Share::checkPermissions( $this->iUserId, $iPlanId ) ) {

        $aResponse['error'] = 'access_forbidden';
        $aResponse['error_description'] = "You don’t have permission to do this.";
        return Response::json( $aResponse );

      }
      return Response::json(Plan::update_byId($id));
    }

    public function delete_index($id = null)
    {
      if( !Plan_Share::checkPermissions( $this->iUserId, $id ) ) {

        $aResponse['error'] = 'access_forbidden';
        $aResponse['error_description'] = "You don’t have permission to do this.";
        return Response::json( $aResponse );

      }
      return Response::json(Plan::delete_byId($id));
    }

    /**
     *
     * get list of all shared persons by planID
     *
     * @param integer $iPlanId planID
     * @method GET
     * @author Lodoss Team
     * @return JSON
     *
     */
    public function get_shared_list( $iPlanId ) {

      $aResponse['error'] = '';
      $aResponse['error_description'] = '';
      if( !Plan_Share::checkPermissions( $this->iUserId, $iPlanId ) ) {

        $aResponse['error'] = 'access_forbidden';
        $aResponse['error_description'] = "You don’t have permission to do this.";
        return Response::json( $aResponse );

      }

      $aResponse = array();
      $aSharedApproved  = Plan_Share::where( 'plan_id', '=', $iPlanId )->order_by('updated_at', 'desc')->get( array( 'id', 'email', 'plan_id', 'user_id', 'permission' ) );

      if( $aSharedApproved ) {

        foreach( $aSharedApproved as $aSharedItem ) {

          // request to get fullname by users_id
          $aSharedItem = $aSharedItem->to_array();
          $sRESTUrl = $this->aConfig['SERVER_URL'] . "/api/user/byemail?email=" . $aSharedItem['email'] . "&access_token=" . Session::get( 'userdata.token' );
          $oRestGetRequest = Httpful::get( $sRESTUrl )->send();

          if( $oRestGetRequest->body->error == '' ) {

            $oUser = $oRestGetRequest->body->user;
            $aSharedItem['fullname'] = $oUser->firstname . " " . $oUser->lastname;

          }

          $aSharedItem['status'] = 'approved';
          array_push( $aResponse, $aSharedItem );

        }

      }

      $aSharedPending   = Sharecodes::where( 'plan_id', '=', $iPlanId )->order_by('updated_at', 'desc')->get( array( 'id', 'email', 'plan_id', 'permission' ) );
      if( $aSharedPending ) {

        foreach( $aSharedPending as $aSharedItem ) {

          $aSharedItem = $aSharedItem->to_array();
          $aSharedItem['status'] = 'pending';
          array_push( $aResponse, $aSharedItem );

        }

      }

      return Response::json( $aResponse );

    }

    /**
     *
     * change permissions
     *
     * @param JSON Request
     * @method PUT
     * @author Lodoss Team
     * @return JSON
     *
     */
    public function put_change_permissions_to_plan() {

      $aResponse['error'] = '';
      $aResponse['error_description'] = '';
      $oRequest = Input::json();

      if( !$oRequest ) {

        $aResponse['error'] = 'bad_request';
        $aResponse['error_description'] = 'Bad request';

      } else {

        if( isset( $oRequest->status ) AND $oRequest->status ) {

          if( !Plan_Share::checkPermissions( $this->iUserId, $oRequest->plan_id ) ) {

            $aResponse['error'] = 'access_forbidden';
            $aResponse['error_description'] = "You don’t have permission to do this.";
            return Response::json( $aResponse );

          }

          switch ( $oRequest->status ) {

            case 'approved':
              $oPlanShares = Plan_Share::where( 'plan_id', '=', $oRequest->plan_id )
              ->where( 'user_id', '=', $oRequest->user_id )
              ->where( 'email', '=', $oRequest->email );

              if( !is_null( $oPlanShares->first() ) ) {

                if( $oRequest->permission == 'edit' OR $oRequest->permission == 'view'  ) {

                  $iPermission = ( $oRequest->permission == 'view' ? 1 : 2  );
                  $oPlanShares = $oPlanShares->first();
                  $oPlanShares->permission = $iPermission;
                  $oPlanShares->save();
                  $aResponse['result'] = 'success';

                } else {

                  $aResponse['error'] = 'bad_request';
                  $aResponse['error_description'] = 'Bad request';

                }

              } else {

                $aResponse['error'] = 'share_not_found';
                $aResponse['error_description'] = 'Share not found';

              }
              break;

            case 'pending':
              $oSharecodes = Sharecodes::where( 'plan_id', '=', $oRequest->plan_id )
              ->where( 'email', '=', $oRequest->email );

              if( !is_null( $oSharecodes->first() ) ) {

                if( $oRequest->permission == 'edit' OR $oRequest->permission == 'view'  ) {

                  $iPermission = ( $oRequest->permission == 'view' ? 1 : 2  );
                  $oSharecodes = $oSharecodes->first();
                  $oSharecodes->permission = $iPermission;
                  $oSharecodes->save();
                  $aResponse['result'] = 'success';

                } else {

                  $aResponse['error'] = 'bad_request';
                  $aResponse['error_description'] = 'Bad request';

                }

              } else {

                $aResponse['error'] = 'share_not_found';
                $aResponse['error_description'] = 'Share not found';

              }
              break;

            default:
              $aResponse['error'] = 'bad_request';
              $aResponse['error_description'] = 'Bad request';
              break;

          }

        } else {

          $aResponse['error'] = 'bad_request';
          $aResponse['error_description'] = 'Bad request';

        }

      }

      return Response::json( $aResponse );

    }

    /**
     *
     * unshare user  from plan
     *
     * @param JSON Request
     * @method DELETE
     * @author Lodoss Team
     * @return JSON
     *
     */
    public function delete_unshare() {

      $aResponse['error'] = '';
      $aResponse['error_description'] = '';
      $oRequest = Input::json();

      if( !$oRequest ) {
        $aResponse['error'] = 'bad_request';
        $aResponse['error_description'] = 'Bad request';

      } else {

        if( isset( $oRequest->status ) AND $oRequest->status ) {

          switch ( $oRequest->status ) {

            case 'approved':
              $oPlanShares = Plan_Share::where( 'plan_id', '=', $oRequest->plan_id )
              ->where( 'user_id', '=', $oRequest->user_id )
              ->where( 'email', '=', $oRequest->email )
              ->where('permission', '!=', 3);

              if( !is_null( $oPlanShares->first() ) ) {
                $oPlanShares->delete();
                $aResponse['result'] = 'success';

                // Delete notifications
                Notification::where( "to", "=", $oRequest->user_id )
                ->where( "plan_id", "=", $oRequest->plan_id )->delete();

              } else {
                $aResponse['error'] = 'share_not_found';
                $aResponse['error_description'] = 'Share not found';
              }
              break;

            case 'pending':
              $oSharecodes = Sharecodes::where( 'plan_id', '=', $oRequest->plan_id )
              ->where( 'email', '=', $oRequest->email );

              if( !is_null( $oSharecodes->first() ) ) {
                $oSharecodes->delete();
                $aResponse['result'] = 'success';
              } else {
                $aResponse['error'] = 'share_not_found';
                $aResponse['error_description'] = 'Share not found';
              }
              break;

            default:
              $aResponse['error'] = 'bad_request';
              $aResponse['error_description'] = 'Bad request';
              break;

          }

        } else {

          $aResponse['error'] = 'bad_request';
          $aResponse['error_description'] = 'Bad request';

        }

      }

      return Response::json( $aResponse );

    }



    /**
     *
     * get permissions
     *
     * @param JSON Request
     * @method GET
     * @author Lodoss Team
     * @return JSON
     *
     */
    public function get_permissions( $iPlanId ) {

      $aResponse['error'] = '';
      $aResponse['error_description'] = '';

      $oPlanShares = Plan_Share::where( 'user_id', '=', Session::get( 'userdata.user.id' ) )
      ->where( 'plan_id', '=', $iPlanId );
      $oPermission = $oPlanShares->first( array( 'permission' ) );
      if( $oPermission ) {

        $aResponse['result'] = intval( $oPermission->permission );

      } else {

        $aResponse['error'] = 'share_not_found';
        $aResponse['error_description'] = 'Bad request';

      }

      return Response::json( $aResponse );

    }


    /**
     *
     * clean blank plans
     *
     * @param JSON Request
     * @method GET
     * @author Lodoss Team
     * @return void
     *
     */
    public function get_cleanBlankPlans() {
      if( Session::has( 'userdata' ) ) {
        Plan::where( 'title', '=', '' )->where( 'user_id', '=', $this->iUserId )->delete();
        Plan::where( 'title', '=', '' )->where( 'user_id', '=', 0 )->delete();
      }
    }


  }
