require 'api_image_preprocessor'
require 'privileged_event'
require 'api_error'

module API
  module Concern
    module Events
      extend ActiveSupport::Concern

      included do
        desc "Returns list of latest events"
        params do
          optional :access_token, type: String, desc: 'User access token, if supplied private event where user have joined will be listed'
          optional :page, type: Integer, desc: 'Events page number', default: 1
          optional :per_page, type: Integer, desc: 'Number of events per page', default: 25
        end
        get '/events' do
          authenticate_user! if params[:access_token]

          events = EventManager.new(current_user).latest
          events = events.page(page).per(per_page).tap do |e|
            e.each {|event| event.accessing_user = current_user}
          end
          success! events.as_api_response(:complete), 200
        end

        desc "Get all event with current keyword"
        params do
          optional :access_token, type: String, desc: 'User access token, if supplied private event where user have joined will be listed'
          requires :keyword, type: String, desc: "Keyword for search, should contain one word without spaces"
        end
        get '/events/keyword' do
          authenticate_user! if params[:access_token]
          current_keyword = Keyword.find_by word: params[:keyword]
          begin
            raise "Keyword not found" if current_keyword.blank?
            success! current_keyword.events.as_api_response(:complete), 200
          rescue => e
            throw_error! 404, e.class.to_s, e.message
          end

        end

        desc "return an event data"
        params do
          optional :access_token, type: String, desc: 'User access token, if supplied private event where user have joined will be listed'
          optional :read_after_login, coerce: Virtus::Attribute::Boolean, desc: "If true then all ActiveEventInvitation for current user will be removed, value either 0 or 1"
        end
        get '/events/:id' do
          begin
            authenticate_user! if params[:access_token]
            event = EventManager.new(current_user).find params[:id]
            event.accessing_user = current_user
            ActiveEventInvitation.find_by_recipient(current_user.email).try(:destroy) if params[:read_after_login].present? && params[:read_after_login]
            success! event.as_api_response(:complete), 200
          rescue => e
            throw_error! 403, e.class.to_s, e.message
          end
        end

        desc "return an event data for cover"
        params do
          optional :access_token, type: String, desc: 'User access token'
        end
        get '/events/:id/cover_info' do
          begin
            authenticate_user!  if params[:access_token]
            event = EventManager.new(current_user).find params[:id]
            event.accessing_user = current_user
            success! event.as_api_response(:complete), 200
          rescue => e
            throw_error! 403, e.class.to_s, e.message
          end
        end

        namespace :events do
          before do
            authenticate_user!
          end

          # create event API endpoint
          desc "Create event for currently logged in user"
          params do
            requires :access_token, desc: 'User access token'
            requires :name, desc: 'Event name'
            requires :description, desc: 'Event description'
            requires :start_time, type: DateTime, desc: 'Event start time'
            requires :end_time, type: DateTime, desc: 'Event end time'
            optional :tag_list, type: String, desc: "comma-separated list of tags for the event"
            optional :privacy, type: String, values: ['public', 'private'], desc: 'Event privacy, default to public'
            optional :private_type, type: Integer, values: Event::PRIVATE_TYPES.each_with_index.map { |x,i| i+0 }, desc: Event::PRIVATE_TYPES.each_with_index.map { |x,i| "#{i+0} - #{x.titleize}<br>" }
            optional :featured, coerce: Virtus::Attribute::Boolean, desc: "Event featured attribute, value either 0 or 1"
            optional :keywords, type: String, desc: "Sting of keywords for this event"
            group :cover_image, type: Hash do
              requires :content_type, type: String, values: ['image/jpg', 'image/jpeg', 'image/png'], default: 'image/jpeg', desc: 'Cover image content type'
              requires :file_name, type: String, desc: 'Cover image file name'
              requires :data, type: String, desc: 'Base64-encoded of cover image file data'
            end
            group :location, type: Hash do
              requires :latitude, type: Float, desc: 'Location latitude'
              requires :longitude, type: Float, desc: 'Location longitude'
              requires :address, type: String, desc: 'Location address representation'
            end
          end
          post '/' do
            begin
              image = ApiImagePreprocessor.new(params.cover_image)
              params[:keywords] = params[:keywords].split(', ') if params[:keywords].present?
              event_params = ActionController::Parameters.new(params).permit(:name, :description, :start_time, :end_time, :commentable, :taggable, :shareable, :member_to_member_invitation, :tag_list, :private_type, :featured, :keywords => [])
              event_params.merge!(
                cover_image: image.process,
                location_attributes: params.location,
                privacy: (params.privacy || 'public')
              )

              event = EventManager.new(current_user).create_event(event_params, image)

              event.save
              response = {}
              response[:message] = 'event created'
              success! event.as_api_response(:create), 201, 'saved', response
            rescue => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # update event API endpoint
          desc "Update user event"
          params do
            requires :access_token, desc: 'User access token'
            optional :name, desc: 'Event name'
            optional :description, desc: 'Event description'
            optional :start_time, type: DateTime, desc: 'Event start time'
            optional :end_time, type: DateTime, desc: 'Event end time'
            optional :tag_list, type: String, desc: "comma-separated list of tags for the event"
            optional :privacy, type: String, values: ['public', 'private'], desc: 'Event privacy, either public or private'
            optional :private_type, type: Integer, values: Event::PRIVATE_TYPES.each_with_index.map { |x,i| i+0 }, desc: Event::PRIVATE_TYPES.each_with_index.map { |x,i| "#{i+0} - #{x.titleize}<br>" }
            optional :featured, coerce: Virtus::Attribute::Boolean, desc: "Event featured attribute, value either 0 or 1"
            optional :keywords, type: String, desc: "Sting of keywords for this event"
            optional :cover_image, type: Hash do
              optional :content_type, type: String, values: ['image/jpg', 'image/jpeg', 'image/png'], default: 'image/jpeg', desc: 'Cover image content type'
              optional :file_name, type: String, desc: 'Cover image file name'
              optional :data, type: String, desc: 'Base64-encoded of cover image file data'
            end
            optional :location, type: Hash do
              requires :latitude, type: Float, desc: 'Location latitude'
              requires :longitude, type: Float, desc: 'Location longitude'
              requires :address, type: String, desc: 'Location address representation'
            end
          end
          put ':id' do
            begin
              event = EventManager.new(current_user).find params[:id]
              EventAuthorization.new(event, current_user).authorize(:update_event)

              if params[:cover_image].keys.length == 3 &&
                params[:cover_image].keys.all? { |key| %i(content_type file_name data).include?key.to_sym }
                @image = ApiImagePreprocessor.new(params[:cover_image])
                event.cover_image = @image.process
              end
              if params[:location]
                event.location_attributes = params[:location]
              end

              params[:keywords] = params[:keywords].split(', ') if params[:keywords].present?
              event_params = ActionController::Parameters.new(params).permit(:name, :description, :start_time, :end_time, :commentable, :taggable, :shareable, :member_to_member_invitation, :tag_list, :private_type, :featured, :keywords => [])

              event.privacy = params[:privacy] if params[:privacy]
              event.save event_params
              @image.clean if @image
              event.accessing_user = current_user
              after_save event, 200, 'event updated', :complete
            rescue UpdateEventError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # change event privacy
          desc "Change event privacy"
          params do
            requires :access_token, type: String, desc: 'User access token'
            requires :privacy, type: String, values: ['public', 'private'], desc: 'Event privacy, either public or private'
            optional :private_type, type: Integer, values: Event::PRIVATE_TYPES.each_with_index.map { |x,i| i+0 }, desc: Event::PRIVATE_TYPES.each_with_index.map { |x,i| "#{i+0} - #{x.titleize}<br>" }
          end
          put ':id/set_privacy' do
            begin
              event = EventManager.new(current_user).find params[:id]
              EventAuthorization.new(event, current_user).authorize(:update_event_privacy)
              event_params = ActionController::Parameters.new(params).permit(:private_type)
              params.privacy == 'public' ? event.set_as_public! : event.set_as_private!
              event.accessing_user = current_user
              event.save event_params
              after_save event, 200, "event set as #{event.privacy}"
            rescue UpdateEventPrivacyError, NotAuthorizedError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # close event
          desc "Close an event. Closed event cannot be joined anymore."
          params do
            requires :access_token, type: String, desc: 'User access token'
          end
          put ':id/close' do
            begin
              event = EventManager.new(current_user).find params[:id]
              EventAuthorization.new(event, current_user).authorize(:close_event)
              event.close!
              after_save event, 200, 'event closed'
            rescue => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # delete event
          desc "Delete an event."
          params do
            requires :access_token, type: String, desc: 'User access token'
          end
          delete ':id' do
            begin
              event = EventManager.new(current_user).find params[:id]
              EventAuthorization.new(event, current_user).authorize(:delete_event)
              event.destroy!
              event.accessing_user = current_user
              Rails.logger.debug("delete event: #{event.inspect}")
              success! event.as_api_response(:complete), 204, 'event deleted'
            rescue DeleteEventError, NotAuthorizedError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end
        end
      end
    end
  end
end
