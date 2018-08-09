<?php


  /**
   * 
   * @author Lodoss Team
   *
   */
  class Plans_Controller extends Base_Controller 
  {

    private $aConfig;

    public function __construct() 
    {
      parent::__construct();
      $this->aConfig = Laravel\Config::get( 'application.oauth2' );
    }

    public function action_index()
    {
      return View::make('base');
    }

    public function action_create()
    {
      return View::make('base');
    }

    public function action_edit( $iPlanId )
    {
      $bAccess = $this->_check_access_to_paln( $iPlanId );
      if(!$bAccess) {
        Session::flash( 'error', "Access forbidden! You don't have permission to access the requested resource." );
        return Redirect::to( '403' );
      }
      return View::make('base');
    }

    public function action_at_a_glance( $iPlanId ) {
      $bAccess = $this->_check_access_to_paln( $iPlanId );
      if(!$bAccess) {
        Session::flash( 'error', "Access forbidden! You don't have permission to access the requested resource." );
        return Redirect::to( '403' );
      }
      return View::make('base');
    }

    public function action_print($iPlanId = 0)
    {
      $bAccess = $this->_check_access_to_paln( $iPlanId );
      if(!$bAccess) {

        Session::flash( 'error', "Access forbidden! You don't have permission to access the requested resource." );
        return Redirect::to( '403' );

      }

      Plan::createPdf($iPlanId);
      echo file_get_contents(path('public').'/files/'.$iPlanId.'_plan.html');
    }

    public function action_download($iPlanId = 0)
    {
      $bAccess = $this->_check_access_to_paln( $iPlanId );
      if(!$bAccess) {

        Session::flash( 'error', "Access forbidden! You don't have permission to access the requested resource." );
        return Redirect::to( '403' );

      }

      $oPlan = Plan::find($iPlanId);
      Plan::createPdf($iPlanId);

      $sFilename = preg_replace('/[^\w\d]/i', '_', $oPlan->title);
      $content = path('public').'/files/'.$iPlanId.'_plan.pdf';
      return Response::download($content, $sFilename .'.pdf', array('content-type'=>'application/pdf'));

    }


    /**
     *
     * Share
     *
     * @param string $sHash hash
     *
     * @author Lodoss Team
     * @return
     *
     */
    public function action_shared_by_hash( $sHash ) {

      if( !$sHash ) return Response::error('404');
      if( strlen( $sHash ) != 32 ) return Response::error('404');
      $oShareCodes = Sharecodes::where_code( $sHash );
      if( !$oShareCodes->count() ) return Response::error('404');

      if( !Session::has( 'userdata.user.id' ) ) {

        Cookie::put( 'shared_plan_code' , $sHash, $iExpiration = 60 );
        $sRegUrl = $this->aConfig['REGISTER_URL'] . "?client_id=" . $this->aConfig['CLIENT_ID'] . "&client_secret=" . $this->aConfig['CLIENT_SECRET'];
        return Redirect::to( $sRegUrl, 302, true );

      } else {

        // authorized user
        // check code
        $oShareCode = Sharecodes::where_code( $sHash );
        if( $oShareCode->count() ) {

          $oShare = $oShareCode->first();

          // check plan
          $oPlan = Plan::where_id( $oShare->plan_id );
          if( $oPlan->count() ) {
            // if plan exist
            // try to check if plan already has been shared
            $bAlreadyShared = Plan_Share::where( 'plan_id', '=', $oShare->plan_id )
            ->where( 'user_id', '=', Session::get( 'userdata.user.id' ) );

            if( !$bAlreadyShared->count() ) {
              // if plan hasn't been shared
              // doing sharing
              $oPlanShare = new Plan_Share;
              $oPlanShare->plan_id  = $oShare->plan_id;
              $oPlanShare->user_id  = Session::get( 'userdata.user.id' );
              $oPlanShare->permission = $oShare->permission;
              $oPlanShare->email    = $oShare->email;
              $oPlanShare->save();
              Cookie::forget( 'shared_plan_code' );

              // check email where has been shared plan
              // for set as Additional email
              // if user haven't Additional email
              // then set 
              if( $oShare->email != Session::get( 'userdata.user.email' ) ) {

                  $aData = array(

                    "access_token"  => Session::get( 'userdata.token' ),
                    "email"     => $oShare->email,

                  );

                  $sApiUrl    = $this->aConfig['SERVER_URL'] . "/api/additional_emails/add";
                  $oApiRequest  = Httpful::post( $sApiUrl )
                  ->body( $aData )
                  ->sendsForm()
                  ->send();
                  $oApiResponse = $oApiRequest->body;

                  // checking DB errors
                  if( !$oApiResponse->error ) {

                    $sHashCode = $oApiResponse->result;
                    if( $sHashCode ) Email_templates::sendAddAdditionalEmail( $oShare->email, $sHashCode );

                    $oShareCodes->delete();
                    unset( $oShare );

                    $sToken     = Session::get( 'userdata.token' );
                    $sApiUrl    = $this->aConfig['SERVER_URL'] . "/api/additional_emails/get_my?access_token={$sToken}";
                    $oApiRequest  = Httpful::get( $sApiUrl )->send();
                    $oApiResponse = $oApiRequest->body;

                    $aMyAdditionalEmails = array();
                    if( count( $oApiResponse->result ) ) {

                      foreach( $oApiResponse->result as $oItem ) {

                        $aMyAdditionalEmails[] = array(

                          'id'    => $oItem->id,
                          'email'   => $oItem->email,
                          'status'  => $oItem->status,

                        );

                      }

                    }

                    Session::forget( 'userdata.user.additional_emails' );
                    Session::put( 'userdata.user.additional_emails', $aMyAdditionalEmails );

                  }

              }

            }

          }

        }

      }

      return Redirect::to( 'plans' );

    }



    /**
     *
     * check access to plan
     *
     * @param integer $iPlanId  PlanID
     *
     * @author Lodoss Team
     * @return boolean
     *
     */
    private function _check_access_to_paln( $iPlanId ) {

      if( ! Session::has( "userdata" ) ) {
        return false;
      }

      $aSession = Session::get( "userdata" );
      $aPlan    = Plan::where_id( $iPlanId );

      if( !$aPlan->count() ) {
        return false;
      }

      if( $aPlan->first()->user_id != $aSession['user']['id'] ) {

        $mPlanShare = Plan_Share::where( 'plan_id', '=', $iPlanId )->where( 'user_id', '=', $aSession['user']['id'] );

        if( !$mPlanShare->count() ) {
          return false;
        }
      }
      
      return true;
    }

  }
