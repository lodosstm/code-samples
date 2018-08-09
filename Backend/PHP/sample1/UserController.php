<?php

namespace Api\v1;

use Illuminate\Support\Facades\Response;
use Swagger\Annotations as SWG;

/**
 * @SWG\Resource(
 *  apiVersion="1.0",
 *  resourcePath="/users",
 *  description="Users operations",
 *  produces="['application/json']"
 * )
 */

class UserController extends MainController {

  private $rules = [
	'create' => [
	  'first_name' => 'required|max:75|alpha',
	  'password'   => 'required|min:8|confirmed',
	  'email'      => 'required|email|unique:users,email'
	]
  ];

/**
   * @SWG\Api(
   *  path="/",
   *      @SWG\Operation(
   *        method="POST",
   *      summary="Create a user",
   *    @SWG\Parameter(
   *      name="first_name",
   *      description="First Name of new user",
   *      paramType="body",
   *          required=true,
   *          allowMultiple=false,
   *          type="string"
   *        ),
   *    @SWG\Parameter(
   *      name="email",
   *      description="Email of new user",
   *      paramType="body",
   *          required=true,
   *          allowMultiple=false,
   *          type="string"
   *        ),
   *    @SWG\Parameter(
   *      name="password",
   *      description="Password of new user",
   *      paramType="body",
   *          required=true,
   *          allowMultiple=false,
   *          type="string"
   *        ),
   *    @SWG\Parameter(
   *      name="password_confirmation",
   *      description="Password Confirmation of new user",
   *      paramType="body",
   *          required=true,
   *          allowMultiple=false,
   *          type="string"
   *        ),
   *    @SWG\ResponseMessage(code=404, message="User not found")
   *  )
   * )
   */
  public function store()
  {
  	$input     = \Input::only('first_name', 'email', 'password', 'password_confirmation');
  	$validator = $this->validate($input, $this->rules['create']);

  	if($validator->fails())
  	{
  		return $this->response($validator->messages(), 500);
  	}

  	$user  = \User::create(array_only($input, ['first_name', 'email', 'password']));

  	return $this->response($user, 200);
  }

}