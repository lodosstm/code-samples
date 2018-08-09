# == Schema Information
#
# Table name: events
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  description              :text             not null
#  start_time               :datetime         not null
#  end_time                 :datetime         not null
#  cover_image_file_name    :string(255)
#  cover_image_content_type :string(255)
#  cover_image_file_size    :integer
#  cover_image_updated_at   :datetime
#  deleted_at               :datetime
#  created_at               :datetime
#  updated_at               :datetime
#  suspended_at             :datetime
#  is_public                :boolean          default(TRUE)
#  closed_at                :datetime
#  invitation_quota         :integer
#  attendees_count          :integer
#  comments_count           :integer
#  photos_count             :integer
#  cover_image_processing   :boolean
#  slug                     :string(255)
#  trending_weight          :integer          default(0)
#

require 'validator/date_range_validator'
require 'api_error'

class Event < ActiveRecord::Base

  include ActsAs::EventApi
  include Privacy
  include ActionView::Helpers::TextHelper
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include PgSearch
  pg_search_scope :search_by_name,
    against: [:name, :description],
    using: {
      tsearch: { prefix: true, any_word: true }
    }

  protokoll :code, pattern: "E%y%m#####"

  acts_as_paranoid
  acts_as_ordered_taggable
  acts_as_commentable
  acts_as_suspendable
  acts_as_closable
  acts_as_favorable

  PRIVATE_TYPES = %w( all_users friends invited_users )
  STATUSES = %w( active not_started finished )

  has_many :attendances
  has_many :attendees, through: :attendances, source: :user do
    def unsuspended
      where "attendances.suspended_at IS ?", nil
    end

    def suspended
      where "attendances.suspended_at IS NOT ?", nil
    end
  end
  has_many :invitations, class_name: 'EventInvitation'
  has_one  :location, as: :mappable
  has_one  :preference, class_name: '::EventPreference', autosave: true

  has_many :photos, class_name: 'EventPhoto', :dependent => :destroy
  has_many :photos_comments, through: :photos, source: :comments
  has_many :trophies, :dependent => :destroy

  has_many :reported_problems, as: :reported, :dependent => :destroy
  has_many :event_keywords, :dependent => :destroy
  has_many :keywords, through: :event_keywords

  has_many :comments, as: :commentable, :dependent => :destroy
  has_many :favorites, class_name: 'FavorableObject', as: :favorable, :dependent => :destroy
  has_many :favorable_users, through: :favorites, source: :user

  has_many :event_views, class_name: :EventViewer, :dependent => :destroy
  has_many :viewers, through: :event_views, source: :user
  has_many :news, class_name: 'News', as: :newsable, :dependent => :destroy

  has_many :event_communities, class_name: 'EventCommunity', foreign_key: :event_id, :dependent => :destroy
  has_many :communities, through: :event_communities, source: :community

  has_many :active_even_joins, class_name: 'ActiveEventJoin'

  serialize :suspended_history_user_ids, Array

  acts_as_mappable :through => :location

  before_create :initialize_default_setting
  after_create :set_activity_date, :set_privacy_settings, :after_post_processing
  after_update :check_private_type, :check_date, :update_feed

  has_attached_file :cover_image, {
    styles:      Paperclip::STYLES,
    default_url: Paperclip::NO_IMAGE_PATH,
    preserve_files: true
  }.merge(IMAGE_STORAGE)

  process_in_background :cover_image,
    processing_image_url: :processing_image_fallback

  validates_presence_of :name
  validates_with DateRangeValidator, fields: [:start_time, :end_time]
  validates_associated :attendances
  validates :cover_image, attachment_presence: true
  validates_attachment :cover_image,
    content_type: { content_type: Paperclip::IMAGE_CONTENT_TYPES },
    size: { in: 10..3072.kilobytes }

  accepts_nested_attributes_for :location

  after_initialize :ensure_preference

  default_scope { where(is_community: false) }
  scope :active, -> { unsuspended }
  scope :not_finish, -> { active.where "end_time > ?", Time.now }
  scope :ongoing, -> { active.where "start_time <= ? AND end_time >= ?", Time.now, Time.now }
  scope :upcoming, -> { active.where "start_time > ?", Time.now }
  scope :latest, -> { ongoing.order "updated_at DESC" }
  scope :public_events, -> { active.where is_public: true }
  scope :public_from_time, -> (time) { active.where "is_public = true AND updated_at >= ?", time }
  scope :private_events, -> { active.where is_public: false }
  scope :recents, -> { active.order "created_at DESC" }
  scope :recents_by_start_time, -> { active.order "start_time DESC" }
  scope :featured, -> { active.where featured: true }
  scope :not_featured, -> { active.where featured: false }

  def user
    self.owner
  end

  def root_comments
    Comment.where(commentable_id: self.id).where(commentable_type: ['Community', 'Event', 'PrivilegedEvent'])
  end

  class << self
    def filter_by(args)
      args||={}
      results = args[:keyword].present? ? search_for(args[:keyword]) : self
      results
    end

    def friendly_find!(arg)
      Event.unscoped.friendly.find arg
    end

    def update_trending_and_activity!
      Event.active.each do |event|
        TrendingCalculator.update_trending_weight event
      end
    end

    def suspend_user!(event, user)
      owner = event.owner
      EventSuspension.new(event, owner).suspend!(user, true)
      user.accessing_user = owner
      user.event_context = event
      user.save
    end

    def order_by_ids(ids)
      order_by = ["case"]
      ids.each_with_index.map do |id, index|
        order_by << "WHEN id='#{id}' THEN #{index}"
      end
      ids.length == 0 ? order_by = [] : order_by << "end"
      order(order_by.join(" "))
    end

    def like_by_any_keywords(keywords=[])
      joins([:keywords]).where("keywords.word ILIKE ANY ( array[?] )", keywords)
    end

    def order_by_keywords(events, keywords=[])
      all_counts = Hash[events.pluck(:id, 0)]
      iliked_counts = Hash[events.like_by_any_keywords(keywords).map { |a| [a.id, (a.keywords.map(&:word) & keywords).size] }]
      all_counts.merge!(iliked_counts)
      sorted_ids = all_counts.sort_by{|k, v| v}.reverse.map{|k, v| v}
      Event.where("id in (?)", (sorted_ids)).order_by_ids(sorted_ids)
    end

    def tops c = 5
      where('attendees_count is not null').where('comments_count is not null').where('photos_count is not null').
          order('attendees_count desc').order('comments_count desc').order('photos_count desc').limit(c)
    end
  end

  delegate :owner, :members, :moderators, :attendance_for, to: :attendance_service
  delegate :address, to: :location, allow_nil: true, prefix: true
  delegate :display_name, to: :owner, allow_nil: true, prefix: true


  def slug_candidates
    [
      :name,
      [:name, :location_address],
      [:name, :location_address, :owner_display_name],
      [:name, :location_address, :owner_display_name, :id],
      [:name, :location_address, :owner_display_name, :id, :created_at]
    ]
  end

  def ensure_preference
    if new_record?
      build_preference unless preference
    end
  end

  def attendee_status_for(user)
    attendance_for(user).suspended? ? 'suspended' : 'not suspended'
  end

  def role_for(user)
    attendance_for(user) || Naught.build.new
  end

  def view_date_for(user, field)
    view = event_views.where(user: user).first
    date = view.blank? ? Time.at(0) : view[field]
    date.blank? ? Time.at(0) : date
  end

  def new_photos_for(user)
    photos.where('created_at > (?)', view_date_for(user, 'last_view_photos_at'))
  end

  def new_comments_for(user)
    comments.where('created_at > (?)', view_date_for(user, 'last_view_comments_at'))
  end

  def new_members_for(user)
    attendees.where('attendances.created_at > (?)', view_date_for(user, 'last_view_members_at'))
  end

  def counters
    {
      'photos' => photos.size,
      'comments' => comments.size,
      'members' => attendees.size
    }
  end

  def new_counters_for user
    {
      'photos' => new_photos_for(user).size,
      'comments' => new_comments_for(user).size,
      'members' => new_members_for(user).size
    }
  end

  def preferences
    preference.for_event
  end

  def photo_preferences
    preference.for_photo
  end

  def commenters
    User.where(id: root_comments.pluck(:user_id))
  end

  def is_invited(user)
    invite = invitations.find_by(recipient: user.email)
    !invite.nil? && (invite.state == 'pending' || invite.state == 'approve')
  end

  EventPreference.default_settings.each do |name, prefs|
    define_method "#{name}_sub_pref" do
      preference.send "#{name}_sub_pref"
    end

    define_method "#{name}_sub_pref_attributes=".to_sym do |attributes|
      attributes.each do |k, v|
        preference.settings(name).send "#{k}=".to_sym, Virtus::Attribute.build('Boolean').coerce(v)
      end
    end
  end

  def time_by_timezone
    begin
      timezone = Timezone::Zone.new :latlon => [location.latitude, location.longitude]
      {
        start_time: timezone.time(start_time).strftime('%d %B %Y %I:%M %p'),
        end_time: timezone.time(end_time).strftime('%d %B %Y %I:%M %p')
      }
    rescue
      {
        start_time: start_time.strftime('%d %B %Y %I:%M %p'),
        end_time: end_time.strftime('%d %B %Y %I:%M %p')
      }
    end
  end

  def generate_date_noty!(type=nil)
    if (type.nil? || type == 'start_time')
      if start_time > Time.now
        EventStartNotifier.delay(run_at: start_time, job_owner: self, job_owner_options: 'start_time').notify(id)
      else
        EventStartNotifier.notify(id)
      end
    end

    if (type.nil? || type == 'end_time')
      if end_time > Time.now
        EventEndNotifier.delay(run_at: end_time, job_owner: self, job_owner_options: 'end_time').notify(id)
      else
        EventEndNotifier.notify(id)
      end
    end
  end

  def status
    if start_time < Time.now && end_time > Time.now
      STATUSES[0]
    elsif start_time < Time.now && end_time < Time.now
      STATUSES[2]
    else
      STATUSES[1]
    end
  end

  def time_of_before_start
    diff_in_secs = (start_time - Time.now).to_i
    if diff_in_secs < 0
      nil
    else
      mm, ss = diff_in_secs.divmod(60)
      hh, mm = mm.divmod(60)
      dd, hh = hh.divmod(24)
      dd > 0 ? "Event starts in #{pluralize((hh > 0 ? dd += 1 : dd) , 'day')}" :  "Event starts in #{Time.at(diff_in_secs).utc.strftime('%Hh %Mm')}"
    end
  end

  def attendees_and_favorables
    (attendees + favorable_users).uniq
  end

  def update_attributes (attributes={})
    Object.const_get(self.class.name).unscoped.update(self.id, attributes)
  end

  def self.find (event_id)
    self.unscoped.find event_id
  end

  def is_send_push_notifications (user)
    if user != nil
      disallow = UserEventNotification.find_by({user_id: user.id, event_id: self.id})
      return disallow ? false : true
    else
      return true
    end
  end

  def correct_cover_image_url (size)
    if (self.is_community?)
      Community.find(self.id).cover_image.url(size)
    else
      self.cover_image.url(size)
    end
  end

  private
    def initialize_location
      self.build_location unless self.location
    end

    def attendance_service
      @attendance_service ||= AttendanceService.for(self)
    end

    def processing_image_fallback
      options = cover_image.options
      options[:interpolator].interpolate(options[:url], cover_image, :original)
    end

    def initialize_default_setting
      build_preference unless preference
      return true
    end

    def set_privacy_settings
      if !is_public? && [0, 1].include?(private_type)
        preference.settings(:non_event_member).view_photos = true
        preference.settings(:photo_non_event_member).favoritable = true
        save!
      end
      return true
    end

    def set_activity_date
      update_attributes(last_activity_at: created_at)
      return true
    end

    def event_slug
      "#{name} by #{owner.try(:display_name)}"
    end

    def check_private_type
      update(private_type: 0) if is_public_changed? && is_public == true && private_type != 0
      return true
    end

    def check_date
      if start_time_changed?
        Delayed::Job.find_by_owner_and_type(self, 'start_time').destroy_all
        news.start_event_news.destroy_all
        generate_date_noty! 'start_time'
      end
      if end_time_changed?
        Delayed::Job.find_by_owner_and_type(self, 'end_time').destroy_all
        news.end_event_news.destroy_all
        generate_date_noty! 'end_time'
      end
      return true
    end

    def update_feed
      if comments_count_changed? || photos_count_changed? || attendees_count_changed?
        RealtimeNotification.update_counters(self)
      end
      return true
    end

    def after_post_processing
      image_url = self.cover_image.url
      self.update_attributes(s3_image_url: image_url)
      true
    end
end
