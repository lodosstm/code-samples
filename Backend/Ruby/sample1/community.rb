require 'validator/date_range_validator'
require 'api_error'

class Community < Event

  include ActsAs::CommunityApi
  default_scope { where(is_community: true) }

  has_many :event_communities, class_name: 'EventCommunity', foreign_key: :community_id
  has_many :events, through: :event_communities
  has_many :comments, as: :commentable, :dependent => :destroy

  def attach_event(event_id)
    event = Event.where(is_community: false).find(event_id)
    unless self.events.pluck(:id).include?(event_id)
      EventCommunity.new({community_id: self.id, event_id: event_id}).save
    else
      return raise UpdateEventError, "Event already attached"
    end
    self
  end

  def detach_event(event_id)
    event = Event.where(is_community: false).find(event_id)
    if self.events.pluck(:id).include?(event_id)
      EventCommunity.where(community_id: self.id).where(event_id: event_id).destroy_all
    else
      return raise UpdateEventError, "Event do not attached"
    end
    self
  end
end
