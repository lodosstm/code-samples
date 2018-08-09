module ActsAs
  module EventApi
    extend ActiveSupport::Concern
    include ActsAs::SharedApi

    included do
      attr_accessor :accessing_user, :latest_pivot

      api_accessible :create do |t|
        t.add :id
      end

      api_accessible :discovery_list do |t|
        t.add :id
        t.add :name_upcased, as: :name
        t.add :is_public, as: :public
        t.add :start_time
        t.add :start_time_as_string
        t.add :status
        t.add :stat
        t.add :cover_image_with_size, as: :cover_image
        t.add lambda{ |event| event.accessing_user.has_favorited?(event) rescue false }, as: :favorited
        t.add lambda{ |event| event.favorites.size }, as: :favorites_size
        t.add lambda{ |event| event.attendees.include?(event.accessing_user) ? 1 : 0 }, as: :joined
      end

      api_accessible :super_light do |t|
        t.add :id
        t.add :is_community
      end

      api_accessible :very_light, extend: :super_light do |t|
        t.add :name_upcased, as: :name
        t.add :light_stat, as: :stat
      end

      api_accessible :light_with_admin, extend: :very_light do |t|
        t.add lambda{ |event| !!(event.attendance_for(event.accessing_user).suspended? rescue false) }, as: :user_suspended
        t.add lambda{ |event| !!((event.role_for(event.accessing_user).admin? || event.role_for(event.accessing_user).moderator?) rescue false) }, as: :as_admin
      end

      api_accessible :basic do |t|
        t.add :id
        t.add :name_upcased, as: :name
        t.add :description
        t.add :is_public, as: :public
        t.add :private_type
        t.add :featured
        t.add :start_time
        t.add :start_time_as_string
        t.add :end_time_as_string
        t.add :end_time
        t.add :code
        t.add :status
        t.add :time_of_before_start
        t.add :privacy
        t.add lambda{ |event| event.keywords.map{ |keyword| keyword[:word] }.join(', ') }, as: :keywords
        t.add lambda{ |event| event.favorites.size }, as: :favorites_size
        t.add lambda{ |event|
          user = event.owner
          user.accessing_user = event.accessing_user
          user.as_api_response(:default)
        }, as: :user
        t.add lambda{ |event| !!((event.role_for(event.accessing_user).admin? || event.role_for(event.accessing_user).moderator?) rescue false) }, as: :as_admin
        t.add lambda{ |event| !!(event.role_for(event.accessing_user).moderator? rescue false) }, as: :as_moderator
        t.add lambda{ |event| !!(event.attendance_for(event.accessing_user).suspended? rescue false) }, as: :user_suspended
        t.add :is_community
        t.add :created_at
        t.add :updated_at
      end

      api_accessible :default, extend: :basic do |t|
        t.add :cover_image_with_size, as: :cover_image
        t.add :location, template: :default
        t.add :stat
        t.add lambda{ |event|
                event.attendees.include?(event.accessing_user) ? 1 : 0
              }, as: :joined
        t.add lambda{ |event| event.accessing_user.has_favorited?(event) rescue false }, as: :favorited
        t.add lambda{ |event| event.invitations.pluck(:recipient).include?(event.accessing_user.email) rescue false }, as: :invited
        t.add lambda{ |event| Rails.application.routes.url_helpers.s_share_event_url(slug: event.friendly_id||event.id, host: ENV['APP_HOST'] || 'localhost', port: Rails.env.development? ? 3000 : nil) }, as: :event_share_url
        t.add lambda{ |event| Rails.application.routes.url_helpers.s_share_album_url(slug: event.friendly_id||event.id, host: ENV['APP_HOST'] || 'localhost', port: Rails.env.development? ? 3000 : nil) }, as: :album_share_url
        t.add lambda{ |event| Rails.application.routes.url_helpers.s_invite_event_url(code: event.code, host: ENV['APP_HOST'] || 'localhost', port: Rails.env.development? ? 3000 : nil) }, as: :invitation_url
        t.add lambda{ |event| event.preference.as_api_response(:default) rescue nil}, as: :preferences
        t.add :stat_updates
        t.add lambda{ |event| event.photos.order('created_at DESC').limit(3).as_api_response(:basic) }, as: :thumbnail_photos
      end

      api_accessible :bare, extend: :default do |t|
      end

      api_accessible :preferences do |t|
        t.add lambda{ |event| event.preference.as_api_response(:default) rescue nil }, as: :preferences
      end

      api_accessible :complete, extend: :default do |t|
        t.add lambda { |event| event.invitation_quota || 'unlimited' }, as: :invitation_quota
        t.add :trophies, template: :default
        t.add :photos_thumb_urls
        t.add :photos_size
        t.add lambda{ |event| event.is_send_push_notifications(event.accessing_user) }, as: :is_get_notifications
      end

      api_accessible :my_events, extend: :discovery_list do |t|
        t.add lambda{ |event| event.new_photos_for(event.accessing_user).size }, as: :new_photos_size
        t.add lambda{ |event| event.new_comments_for(event.accessing_user).size }, as: :new_comments_size
        t.add lambda{ |event| event.new_members_for(event.accessing_user).size }, as: :new_members_size
      end

      api_accessible :my_events_notification, extend: :my_events do |t|
        t.add lambda{ |event| event.is_send_push_notifications(event.accessing_user) }, as: :is_get_notifications
      end

      def cover_image_with_size
        {original: absolute_url(self.correct_cover_image_url(:original)),
         large:    absolute_url(self.correct_cover_image_url(:large)),
         medium:   absolute_url(self.correct_cover_image_url(:medium)),
         small:    absolute_url(self.correct_cover_image_url(:small)),
         thumb:    absolute_url(self.correct_cover_image_url(:thumb))
        }
      end

      def stat
        HashWithIndifferentAccess.new.tap do |st|
          st[:attendees_count] = self.attendees.count
          st[:photos_count] = self.photos.count
          st[:comments_count] = self.root_comments.count
          st[:favorites_count] =  self.favorites.count
        end
      end

      def light_stat
        HashWithIndifferentAccess.new.tap do |st|
          st[:photos_count] = self.photos.count
        end
      end

      def stat_updates
        latest_pivot_time = latest_pivot.blank? ? Time.now : Time.at(latest_pivot.to_i)
        HashWithIndifferentAccess.new.tap do |st|
          st[:attendees_count] = self.attendances.where('joined_at >= ?', latest_pivot_time).count
          st[:photos_count] = self.photos.where('created_at >= ?', latest_pivot_time).count
          st[:comments_count] = self.root_comments.where('created_at >= ?', latest_pivot_time).count
        end
      end

      def name_upcased
        self.name.upcase
      end

      def start_time_as_string
        self.start_time.strftime('%d %B %Y %I:%M %p')
      end

      def end_time_as_string
        self.end_time.strftime('%d %B %Y %I:%M %p')
      end

      def photos_thumb_urls
        begin
          EventAuthorization.new(self, self.accessing_user).authorize(:list_event_photos)
          self.photos.order('created_at DESC').as_api_response(:very_light)
        rescue => e
          self.photos.order('created_at DESC').limit(4).as_api_response(:very_light)
        end
      end

      def photos_size
        self.photos.size
      end

    end
  end
end