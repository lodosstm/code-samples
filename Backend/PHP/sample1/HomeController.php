<?php

class HomeController extends BaseController
{
  /**
   * Choosing template and saving result of payment
   * 
   * @return Illuminate\View
   */
  private function normal()
  {
    $question = NULL;
    $template = 'partials._form';

    if(Cookie::get('user') == NULL)
    {
      $result = new Results;
      $result->complete = false;
      $result->payment = false;
      $result->save();
      Cookie::queue('user', $result->id, 43200);
      $question = Questions::firstFromGroup(Config::get('app.group'));
    }
    else
    {
      $question = Questions::current(Config::get('app.group'), Cookie::get('user'));
    }

    if($question != NULL)
    {
      return View::make('index', array(
                        'title'  => Config::get('app.app_name'),
                        'slogan' => Config::get('app.slogan'),
                        'awards' => Config::get('app.awards'),
                        'testimonials' => Testimonials::all(),
                        'question' => $question,
                        'answers' => $question->answers,
                        'template' => $template,
                        'progress' => Questions::getProgress(Config::get('app.group'), Cookie::get('user'))
                        ));
    }
    else
    {
      $template = 'partials._complete';
      return View::make('index', array(
                        'title'  => Config::get('app.app_name'),
                        'slogan' => Config::get('app.slogan'),
                        'awards' => Config::get('app.awards'),
                        'testimonials' => Testimonials::all(),
                        'template' => $template
                        )
      );
    }
  }

  /**
   * Checking successful payment and returning the info
   * 
   * @param int $id
   * @return Illuminate\View
   */
  private function activated($id)
  {
    $results = Results::find($id);
    if($results != NULL)
    {
      if($results->payment)
      {
        $limit = Config::get('app.access_time') * 24 * 60 * 60;
        if(strtotime($results->updated_at) + $limit >= time())
        {
          return View::make('index', array(
                    'res' => DietList::find($results->dietlist_id),
                    'title'  => Config::get('app.app_name'),
                    'slogan' => Config::get('app.slogan'),
                    'awards' => Config::get('app.awards'),
                    'testimonials' => Testimonials::all(),
                    'template' => 'result'
                  )
          );
        }
        else
        {
          return Response::make("Time of access ended", 403); 
        }
      }
      else
      {
        return Response::make("Not payment", 403);
      }
    }
    else
    {
      return Response::make("Page not found", 404);
    }
  }

  /**
   * Action of index route
   * 
   * @return Illuminate\View
   */
  public function index()
  {
    if(Input::has('id'))
    {
      return $this->activated(Input::get('id'));        
    }
    else
    {
      return $this->normal();
    }
  }

  /**
   * Action of next step for the form 
   * 
   * @return Illuminate\View
   */
  public function next()
  {
    $activity = new Activity;
    $activity->user_hash = Cookie::get('user');
    $activity->question = Input::get('question_id');
    $activity->answer = Input::get('answer');
    $activity->save();

    $question = Questions::current(Config::get('app.group'), Cookie::get('user'));

    if($question != NULL)
    {
      return Response::json(array(
                            'question' => $question->toJson(),
                            'answers'  => $question->answers->toJson(),
                            'progress' => Questions::getProgress(Config::get('app.group'), Cookie::get('user')),
                            'complete' => 0
                            )
      );
    }
    else
    {
      return $this->complete(Cookie::get('user'));
    }
  }

  /**
   * Saving the last step data and generating the SMS code
   * 
   * @param int $user_id
   * @return Illuminate\View
   */
  protected function complete($user_id)
  {
    $results = Results::find($user_id);
    $smscode = generateSmsCode();

    if($results != NULL)
    {
      $activity = Activity::where('user_hash', '=', $user_id)->get();
      $rate = 0;

      foreach($activity as $act)
      {
        $rate += $act->answers->rate;
      }
      $results->complete = true;
      $results->total_rate = $rate;
      $results->smscode = $smscode;

      $results->save();
      
      return completeResponse($smscode);
    }
    else
    {
      return false;
    }
  }

  /**
   * Action of final step for the form 
   * 
   * @return Illuminate\View
   */
  public function getComplete() {
    if(Config::get('app.debug'))
    {
      $template = 'partials._complete';
      return View::make('index', array(
                        'title'  => Config::get('app.app_name'),
                        'slogan' => Config::get('app.slogan'),
                        'awards' => Config::get('app.awards'),
                        'testimonials' => Testimonials::all(),
                        'template' => $template
                        )
      );          
    }
    else
    {
      return Response::make("Page not found", 404);
    }
  }

  /**
   * Checking the SMS code and calculate user answers from the form
   * 
   * @return Illuminate\Http\Response
   */
  public function postResult()
  {
    $results = Results::find(Cookie::get('user'));

    if($results->smscode === Input::get('code'))
    {

      $res = DietList::where('rate_min', '<=', $results->total_rate)
                     ->where('rate_max', '>=', $results->total_rate, 'AND')
                     ->first();
      $results->dietlist_id = $res->id;
      $results->save();

      return Response::make(array(
                            'template' => View::make('result', array('res' => $res))->render()
                            )
      );
    }
    else
    {
      return Response::make("Incorrect SMS code", 403);
    }

  }

  /**
   * Render success result
   * 
   * @param int $id
   * @return Illuminate\Http\Response
   */
  public function getResult($id = null)
  {
    $condition = $id === null ? Cookie::get('user') : $id;
    $results = Results::find($condition);
    $res = DietList::find($results->dietlist_id);
    
    return View::make('index', array(
                        'res' => $res,
                        'title'  => Config::get('app.app_name'),
                        'slogan' => Config::get('app.slogan'),
                        'awards' => Config::get('app.awards'),
                        'testimonials' => Testimonials::all(),
                        'template' => 'result'
                      )
    );
  }

}