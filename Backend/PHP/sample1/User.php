<?php

use Illuminate\Auth\UserInterface;
use Illuminate\Database\Eloquent\Collection;
use Carbon\Carbon;

class User extends Eloquent implements UserInterface {

	protected $table = 'users';
	protected $guarded = ['id'];
	protected $dates = ['trial_ends_at', 'subscription_ends_at', 'last_login_at'];
	protected $hidden = ['password'];

	public function updateLastLogin()
	{
		$this->last_login_at = Carbon::now();
		$this->save();
	}

	/**
	 * Get a collection of users that this user is sharing an event with.
	 *
	 * @return Illuminate\Database\Eloquent\Collection
	 */
	public function sharedEventsWith()
	{
		if ($this->events->isEmpty()) {
			return new Collection();
		}

		$event_ids = $this->sharedEvents()->lists('id');

		if (count($event_ids) == 0) {
			return new Collection();
		}

		$user_ids = DB::table('shared_events')
			->distinct()
			->whereIn('event_id', $event_ids)
			->lists('user_id');

		if (count($user_ids) == 0) {
			return new Collection();
		}

		return User::whereIn('id', $user_ids)->get();
	}

	/**
	 * Get a collection of events owned by this user that are being
	 * shared with others.
	 *
	 * @return Illuminate\Database\Eloquent\Collection
	 */
	public function sharedEvents()
	{
		$event_ids = $this->events->lists('id');
		$shared_event_ids = DB::table('shared_events')
			->distinct()
			->whereIn('event_id', $event_ids)
			->lists('event_id');

		if (count($shared_event_ids) == 0) {
			return new Collection();
		}

		return EventModel::whereIn('id', $shared_event_ids)->get();
	}

	/**
	 * Get how many events from someone are being shared with this uer.
	 *
	 * @param integer $user_id
	 * @return integer
	 */
	public function countOfAccessibleEventsByUser($user_id)
	{
		$count = 0;

		foreach ($this->accessibleEvents as $ae) {
			if ($ae->user_id == $user_id) {
				$count++;
			}
		}

		return $count;
	}

	/* RELATIONS */
	public function events()
	{
		return $this->hasMany('EventModel', 'user_id');
	}

	public function expenses()
	{
		return $this->hasMany('UserExpense', 'user_id')->orderBy('updated_at', 'desc');
	}

	public function user_devices()
	{
		return $this->hasMany('UserDevice', 'user_id');
	}

	// Events shared with this user
	public function accessibleEvents()
	{
		return $this->belongsToMany('EventModel', 'shared_events', 'user_id', 'event_id')->withPivot('permissions');
	}

	public function invitations()
	{
		return $this->hasMany('Invitation', 'invited_by');
	}

	/**
	 * Get the unique identifier for the user.
	 *
	 * @return mixed
	 */
	public function getAuthIdentifier()
	{
		return $this->getKey();
	}

	/**
	 * Get the password for the user.
	 *
	 * @return string
	 */
	public function getAuthPassword()
	{
		return $this->password;
	}

	/**
	 * Get the token value for the "remember me" session.
	 *
	 * @return string
	 */
	public function getRememberToken()
	{
		return $this->remember_token;
	}

	/**
	 * Set the token value for the "remember me" session.
	 *
	 * @param  string  $value
	 * @return void
	 */
	public function setRememberToken($value)
	{
		$this->remember_token = $value;
	}

	/**
	 * Check that user is admin of shared event
	 *
	 * @param integer $event_id
	 * @return Illuminate\Database\Eloquent\Collection
	 */
	public function adminOfSharedEvent($event_id)
	{
		$admin_permission = DB::table('shared_events')
			->where('event_id', $event_id)
			->where('user_id', $this->id)
			->where('permissions', 'administrator')
			->first();

		if ($admin_permission and $admin_permission->id) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Save avatar to disk and its filename in the database.
	 *
	 * @param  string $source
	 * @return void
	 */
	public function saveAvatar($source)
	{
		$where = public_path() . '/uploads/avatars/';

		// Generate unique filename
		do {
			$filename = Str::random(40);
		} while (File::exists($where . $filename . '.jpg'));

		// Resize and save
		Image::make($source)->resize(25, 25)->save($where . $filename . '.jpg');

		// Save filename in the database
		$this->avatar_filename = $filename;
		$this->save();
	}

	/**
	 * Return relative URL to the avatar.
	 * 
	 * @return string
	 */
	public function avatarAbsoluteUrl()
	{
		if ($this->avatar_filename == '') {
			return '/images/profile-pic.jpg';
		} else {
			return '/uploads/avatars/' . $this->avatar_filename . '.jpg';
		}
	}

}
