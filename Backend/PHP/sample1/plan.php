<?php


/**
 *
 * Plan model
 *
 * @author Lodoss Team
 *
 */
class Plan extends Elegant {

  public static $timestamps = true;

  public function targets()
  {
    return $this->has_many('Target');
  }

  protected $aValidationRules = array(
    'title'         => 'required',
    'user_id'       => 'required|integer',
  );

  protected $aInvalidMessages = array(

    'title_required'          => "Field 'Plan Title' is required.",
    'user_id_required'        => "Field 'user_id' is required.",
    'user_id_integer'         => "Field 'user_id' may only contain numbers.",
  );

  public static function get_allPlans($iLimit = '', $iOffset = 0)
  {
    $aResult['error'] = '';
    $aResult['error_description'] = '';
    $aCurrentUser = Session::get( 'userdata.user' );
    if($iLimit != 'all' && $iLimit != '') {
      $aPlans   = DB::table('plans')
        ->left_join('plan_shares', 'plans.id', '=', 'plan_shares.plan_id')
        ->left_join('plan_shares as ps', 'ps.plan_id', '=', 'plan_shares.plan_id')
        ->where('plan_shares.user_id', '=', $aCurrentUser['id'])
        ->group_by('ps.plan_id')
        ->take($iLimit)
        ->skip($iOffset)
        ->get(array('plans.*', DB::Raw('group_concat(ps.user_id) as users')));
    } else {
      $aPlans   = DB::table('plans')
        ->left_join('plan_shares', 'plans.id', '=', 'plan_shares.plan_id')
        ->left_join('plan_shares as ps', 'ps.plan_id', '=', 'plan_shares.plan_id')
        // check this condition
        ->where('plan_shares.user_id', '=', $aCurrentUser['id'])
        ->group_by('ps.plan_id')
        ->get(array('plans.*', DB::Raw('group_concat(ps.user_id) as users')));
    }

    //set sharedWithMe property
    foreach ($aPlans as $key => $value) {
      $value->sharedWithMe = 0;
      if($value->user_id != $aCurrentUser['id']) {
        $value->sharedWithMe = 1;
      }
    }

    $aResult['plans'] = $aPlans;
    return $aResult;
  }

  public static function get_byId($id = 0)
  {
    $aResult['error'] = '';
    $aResult['error_description'] = '';
    $aResult['plan'] = Plan::find($id)->original;
    return $aResult;
  }

  public static function get_byUserId($iUserId = 0)
  {
    $aResult['error'] = '';
    $aResult['error_description'] = '';
    $aResult['plans'] = Plan::where('user_id', '=', $iUserId)->get();
    return $aResult;
  }

  public static function get_countSimilarName()
  {
    $aResult['error'] = '';
    $aResult['error_description'] = '';
    $session = Session::get('userdata');
    $aResult['count'] = DB::table('plans')->where('title', 'LIKE', Input::get('planname').'%')->where('user_id', '=', $session['user']['id'])->count();
    return $aResult;
  }

  public static function copy_byPlanId($iPlanId = 0) {

    $aResult['error'] = '';
    $aResult['error_description'] = '';
    $aPlanTargets     = array();
    $aPlanTasts       = array();

    //get plan related objects
    $oPlan        = Plan::find($iPlanId);
    $aTempTargets = Plan_Target::get_byPlanId($oPlan->id);
    $aTempWeeks   = Plan_Week::get_byPlanId( $iPlanId );

    if($aTempTargets['error'] == '') {
      $aPlanTargets = $aTempTargets['targets'];
    }
    foreach ($aPlanTargets as $key => $oTarget) {
      $aTempTasks = Plan_Target_Task::get_byTargetId($oTarget->id);
      if($aTempTasks['error'] == '') {
        $aPlanTasts[$oTarget->id] = $aTempTasks['tasks'];
      } 
    }

    /*save new objects*/
    $oPlanNew = new Plan;
    $oPlanNew->fill($oPlan->attributes);
    $oPlanNew->id = 0;
    $input = Input::get();

    if(!empty($input['planname'])) {

      $oPlanNew->title  = $input['planname'];

    }

    $oPlanNew->user_id  = Session::get( 'userdata.user.id' );
    $oPlanNew->author   = Session::get( 'userdata.user.fullname' );
    $oPlanNew->save();
    $lastId = DB::Query('SELECT LAST_INSERT_ID() as id');
    $oPlanNew->id = $lastId[0]->id;

    //create plan owner permission
    $oPlanShare           = new Plan_Share;
    $oPlanShare->user_id  = Session::get( 'userdata.user.id' );
    $oPlanShare->plan_id  = $oPlanNew->id;
    $oPlanShare->permission = 3;
    $oPlanShare->email    = Session::get( 'userdata.user.email' );
    $oPlanShare->save();

    //copy  weekly summative assessment (table - plan_weeks)
    if( $aTempWeeks['error'] == '' AND $aTempWeeks['weeks'] ) {
      foreach( $aTempWeeks['weeks'] as $oTempWeek ) {

        $oPlanWeeks = new Plan_Week;
        $oPlanWeeks->fill( (array)$oTempWeek );
        $oPlanWeeks->id = 0;
        $oPlanWeeks->plan_id = $oPlanNew->id;
        $oPlanWeeks->save();

      }

    }

    foreach ($aPlanTargets as $oTarget) {

      $aPlanTastsOld    = $aPlanTasts[$oTarget->id];
      $oTargetNew       = new Plan_Target;
      $oTargetNew->fill((array)$oTarget);
      $oTargetNew->id       = 0;
      $oTargetNew->plan_id  = $oPlanNew->id;
      $oTargetNew->save();
      $lastId = DB::Query('SELECT LAST_INSERT_ID() as id');
      $oTargetNew->id = $lastId[0]->id;

      foreach ($aPlanTastsOld as $oTask) {
        $oTaskNew         = new Plan_Target_Task;
        $oTaskNew->fill((array)$oTask);
        $oTaskNew->id       = 0;
        $oTaskNew->target_id  = $oTargetNew->id;
        $oTaskNew->save();
      }
    }

    return $aResult;
  }

  public static function createPlan()
  {
    $aResult['error']   = '';
    $aResult['error_description'] = '';

    $aSrcPlan = (array)Input::json()->plan;

    if(isset($aSrcPlan['sharedWithMe'])) {
      unset($aSrcPlan['sharedWithMe']);
    }

    $aFilteredPlan = $aSrcPlan;

    $oPlan = new Plan;
    $oPlan->fill( $aFilteredPlan );
    $oPlan->save();
    $oPlan = Plan::find($oPlan->id);
    $aResult['plan']  = $oPlan->to_array();

    //create plan owner permission
    $oPlanShare       = new Plan_Share;
    $oPlanShare->user_id  = $oPlan->user_id;
    $oPlanShare->plan_id  = $oPlan->id;
    $oPlanShare->permission = 3;
    $oPlanShare->email = Session::get( 'userdata.user.email' );
    $oPlanShare->save();

    for($week = 1; $week < 5; $week++) {
      $oPlanWeek = new Plan_Week;
      $oPlanWeek->plan_id = $oPlan->id;
      $oPlanWeek->week = $week;
      $oPlanWeek->save();
    }
    return $aResult;
  }

  public static function update_byId($id = 0)
  {
    $aResult['error'] = '';
    $aResult['error_description'] = '';
    if($id) {

      $aSrcPlan = (array)Input::json()->plan;
      //remove flag
      if(isset($aSrcPlan['sharedWithMe'])) {
        unset($aSrcPlan['sharedWithMe']);
      }

      if( isset( $aSrcPlan['permission'] ) ) unset( $aSrcPlan['permission'] );
    
      $aFilteredPlan = $aSrcPlan;

      $oPlan = Plan::find( $id );
      if($oPlan) {
        $oPlan->fill( $aFilteredPlan );
        if($oPlan->validate( $aFilteredPlan ) ) {
          $oPlan->save();
        } else {
          $aResult['error'] = 'plan_create';
          $aResult['error_description'] = (array)$oPlan->errors();
        }
      } else {
        $aResult['error'] = 'plan_update';
        $aResult['error_description'] = 'plan do not exists';
      }
    } else {
      $aResult['error'] = 'plan_update';
      $aResult['error_description'] = 'please provide plan id';
    }
    return $aResult;
  }

  public static function delete_byId($id = 0)
  {
    $aResult['error'] = '';
    $aResult['error_description'] = '';
    if($id) {
      $oPlan = Plan::find($id);
      if($oPlan) {
        if(Session::get( 'userdata.user.id' ) == $oPlan->user_id) {
          $oPlan->delete();
        } else {
          $aResult['error'] = 'plan_delete';
          $aResult['error_description'] = 'You don’t have permission to do this.';  
        }
      } else {
        $aResult['error'] = 'plan_delete';
        $aResult['error_description'] = 'plan do not exists';
      }
    } else {
      $aResult['error'] = 'plan_delete';
      $aResult['error_description'] = 'please provide plan id';
    }
    return $aResult;
  }

  public static function createPdf( $id = 0 )
  {
    $plan = Plan::find( $id );

    //do escape spesial chars
    foreach ($plan->attributes as $key => $item) {
      $plan->$key = htmlentities($item, ENT_QUOTES, 'UTF-8', false);
    }


    if( isset( $plan->implementation_date ) AND $plan->implementation_date AND $plan->implementation_date != "0000-00-00 00:00:00" ) {

      $plan->implementation_date = date( "n/j/Y", strtotime($plan->implementation_date) );

    } else {

      $plan->implementation_date = "";

    }

    $targets = Plan_Target::get_byPlanIdGroupBy( $plan->id , 'week' , 'week' );

    //do escape spesial chars for targets
    foreach ($targets['targets'] as $target) {
      foreach ($target[0]->attributes as $key => $value) {
        $target[0]->$key = htmlentities($value, ENT_QUOTES, 'UTF-8', false);
      }
    }

    $aPlanWeeks = Plan_Week::get_byPlanId($plan->id);


    $aStandards = explode( "\n", $plan->standard );
    $aNewStandards = "<div>" . implode("</div>\n<div>", $aStandards) . "</div>";
    $plan->standard = $aNewStandards;

    //do escape spesial chars for plans weeks
    foreach ($aPlanWeeks['weeks'] as $week) {
      $week->description = htmlentities($week->description, ENT_QUOTES, 'UTF-8', false);
    }
      
    $path = 'public/files/';

    $filename = $id . '_plan';

    $pdfContent = View::make( 'plans.pdfplan', array( 'plan' => $plan, 'targets' => $targets['targets'], 'weeks' => $aPlanWeeks['weeks'] ) );
    $htmlContent = View::make( 'plans.htmlfileplan', array( 'plan' => $plan, 'targets' => $targets['targets'], 'weeks' => $aPlanWeeks['weeks'] ) );
    

    $html2pdf = new HTML2PDF( 'P', 'A4', 'en', false, 'KOI8-R',0 );
    $html2pdf->AddFont('Helvetica','','helvetica.php');
    $html2pdf->pdf->SetFont("Helvetica"); 
    $html2pdf->WriteHTML( $pdfContent );    
    $html2pdf->Output( $path . $filename . '.pdf' , 'F' );

    File::put( $path . $filename . '.html' , $htmlContent );

    return $path . $filename;
  }

}
