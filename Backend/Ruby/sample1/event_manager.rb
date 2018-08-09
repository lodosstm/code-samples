class EventManager
  attr_reader :user

  def initialize(user, is_community = false)
    @user = user
    if is_community
      @model_name = 'Community'
    else
      @model_name = 'Event'
    end
  end

  def new_event
    PrivilegedEvent.new(Object.const_get(@model_name).new, user)
  end

  def find(event_id)
    event = Object.const_get(@model_name).find event_id
    EventAuthorization.new(event, user).authorize(:access_event)
    PrivilegedEvent.new(event)
  rescue Pundit::NotAuthorizedError
    if event.is_invited(user)
      PrivilegedEvent.new(event)
    else
      raise NotAuthorizedError, "You are not authorized to access this event"
    end
  end

  def latest
    return Object.const_get(@model_name).public_events.latest unless user
    return Object.const_get(@model_name).latest if user && user.admin?
    public_events = Object.const_get(@model_name).public_events.pluck(:id)
    invited_events = Object.const_get(@model_name).private_events.joins(:invitations).where('event_invitations.recipient = ?', user.email).pluck(:id)
    user_events = Object.const_get(@model_name).joins(:attendances).where('attendances.event_id = events.id').where('attendances.user_id = ?', user.id).pluck(:id)
    event_ids = (public_events + user_events + invited_events).uniq
    Object.const_get(@model_name).where(id: event_ids.uniq).order("start_time DESC")
  end

  def create_event(args={}, image)
    event = new_event
    event.save(args)
    
    if event.errors.blank?
      event.accessing_user = user
      Feed.create(:create_event, user, event)
      image.clean if image
    end

    event
  end
end
