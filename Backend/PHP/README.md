# Samples of PHP

## First sample

There is a code sample of PHP framework - Laravel. 

There are several files with code:
* [API for plan identity](sample1/api_plans.php)
* [Event controller](sample1/EventController.php)
* [Home controller](sample1/HomeController.php)
* [Plan model](sample1/plan.php)
* [Plan controller](sample1/plans.php)
* [User model](sample1/User.php)
* [User controller](sample1/UserController.php)

This code has 2 identities: user and plan. Each identity has a controller and model. Also there are examples of 2 controllers - Home and Event.

## Second sample

Project for automatization of Real Estate (CRM, Advertising posting, Sites scrapping).

PHP Framework - Laravel 5.1

Code sample contains few parts:
* Hierarchy of classes __BaseController__ -> __BaseModelAPIController__ -> __AdPostAPIController__
  * __BaseController__ - is base and simple controller based on Base Laravel BaseController
  * __BaseModelAPIController__ - is base controller for REST API, it contains functions for filtering, sorting and other
  * __AdPostAPIController__ - REST API Controller for generating and posting Advertising posts at Real Estate platforms
* __LoadCityController__ - CLI Command for Loading list of cities to DataBase
* __AdPost__ , __GeoDistrict__ and __GeoCity__ - Models
* __AuthAPI__ middleware for authentication REST API clients by token

There are several files with code:
* [Commands/LoadCityAddresses](sample2/Commands/LoadCityAddresses.php)
* [Controllers/BaseController](sample2/Controllers/BaseController.php)
* [Controllers/BaseModelAPIController](sample2/Controllers/BaseModelAPIController.php)
* [Controllers/AdPostAPIController](sample2/Controllers/AdPostAPIController.php)
* [Models/AdPost](sample2/Models/AdPost.php)
* [Models/GeoCity](sample2/Models/GeoCity.php)
* [Models/GeoDistrict](sample2/Models/GeoDistrict.php)
* [Middleware/AUthAPI](sample2/Middleware/AuthAPI.php)
