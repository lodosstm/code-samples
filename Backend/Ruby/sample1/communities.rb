require 'api_image_preprocessor'
require 'privileged_event'
require 'api_error'

module API
  module Concern
    module Communities
      extend ActiveSupport::Concern

      included do
        desc "Returns list of latest communities"
        params do
          optional :access_token, type: String, desc: 'User access token'
          optional :page, type: Integer, desc: 'Communities page number', default: 1
          optional :per_page, type: Integer, desc: 'Number of communities per page', default: 25
        end
        get '/communities' do
          authenticate_user! if params[:access_token]

          events = EventManager.new(current_user, true).latest
          events = events.page(page).per(per_page).tap do |e|
            e.each {|event| event.accessing_user = current_user}
          end
          success! events.as_api_response(:light_listing), 200
        end

        desc "return an community data"
          params do
            optional :access_token, type: String, desc: 'User access token, if supplied private event where user have joined will be listed'
            optional :read_after_login, coerce: Virtus::Attribute::Boolean, desc: "If true then all ActiveEventInvitation for current user will be removed, value either 0 or 1"
          end
          get '/communities/:id' do
            begin
              authenticate_user! if params[:access_token]
              event = EventManager.new(current_user, true).find params[:id]
              event.accessing_user = current_user
              ActiveEventInvitation.find_by_recipient(current_user.email).try(:destroy) if params[:read_after_login].present? && params[:read_after_login]
              success! event.as_api_response(:attached_list), 200
            rescue => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

        namespace :joined_communities do
          before do
            authenticate_user!
          end

          desc "Returns list of joined communities"
          params do
            optional :access_token, type: String, desc: 'User access token'
            optional :page, type: Integer, desc: 'Communities page number', default: 1
            optional :per_page, type: Integer, desc: 'Number of communities per page', default: 25
          end
          get '/my' do
            events = current_user.joined_communities.recents.page(page).per(per_page)
            events.each do |u|
              u.accessing_user = current_user
            end
            success! events.as_api_response(:light_listing), 200
          end
        end

        namespace :communities do
          before do
            authenticate_user!
          end

          # create community API endpoint
          desc "Create community for currently logged in user"
          params do
            requires :access_token, desc: 'User access token'
            requires :name, desc: 'Community name'
            requires :description, desc: 'Community description'
            optional :tag_list, type: String, desc: "comma-separated list of tags for the event"
            optional :privacy, type: String, values: ['public', 'private'], desc: 'Community privacy, default to public'
            optional :private_type, type: Integer, values: Event::PRIVATE_TYPES.each_with_index.map { |x,i| i+0 }, desc: Event::PRIVATE_TYPES.each_with_index.map { |x,i| "#{i+0} - #{x.titleize}<br>" }
            optional :featured, coerce: Virtus::Attribute::Boolean, desc: "Community featured attribute, value either 0 or 1"
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

              event = EventManager.new(current_user, true).create_event(event_params, image)
              
              event.save
              response = {}
              response[:message] = 'community created'
              success! event.as_api_response(:create), 201, 'saved', response
            rescue => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # update community API endpoint
          desc "Update user community"
          params do
            requires :access_token, desc: 'User access token'
            optional :name, desc: 'Community name'
            optional :description, desc: 'Community description'
            optional :tag_list, type: String, desc: "comma-separated list of tags for the event"
            optional :privacy, type: String, values: ['public', 'private'], desc: 'Community privacy, either public or private'
            optional :private_type, type: Integer, values: Event::PRIVATE_TYPES.each_with_index.map { |x,i| i+0 }, desc: Event::PRIVATE_TYPES.each_with_index.map { |x,i| "#{i+0} - #{x.titleize}<br>" }
            optional :featured, coerce: Virtus::Attribute::Boolean, desc: "Community featured attribute, value either 0 or 1"
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
              event = EventManager.new(current_user, true).find params[:id]
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
              after_save event, 200, 'community updated', :attached_list
            rescue UpdateEventError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # delete community
          desc "Delete an community."
          params do
            requires :access_token, type: String, desc: 'User access token'
          end
          delete ':id' do
            begin
              event = EventManager.new(current_user, true).find params[:id]
              EventAuthorization.new(event, current_user).authorize(:delete_event)
              event.destroy!
              event.accessing_user = current_user
              success! event.as_api_response(:complete), 204, 'community deleted'
            rescue DeleteEventError, NotAuthorizedError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # attach event to community API endpoint
          desc "Attach event to community"
          params do
            requires :access_token, desc: 'User access token'
            requires :event_id, type: Integer, desc: 'Event id for attaching'
          end
          put ':id/attach' do
            begin
              community = EventManager.new(current_user, true).find params[:id]
              EventAuthorization.new(community, current_user).authorize(:update_event)

              community.attach_event params[:event_id]
              Feed.create(:attach_event_to_community, current_user.id, community.id)

              after_save community, 200, 'Event attached to community', :attached_list
            rescue UpdateEventError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end

          # detach event from community API endpoint
          desc "Detach event from community"
          params do
            requires :access_token, desc: 'User access token'
            requires :event_id, type: Integer, desc: 'Event id for attaching'
          end
          delete ':id/attach' do
            begin
              community = EventManager.new(current_user, true).find params[:id]
              EventAuthorization.new(community, current_user).authorize(:update_event)

              community.detach_event params[:event_id]

              after_save community, 200, 'Event detached to community', :attached_list
            rescue UpdateEventError => e
              throw_error! 403, e.class.to_s, e.message
            end
          end
        end
      end
    end
  end
end
