require 'api_error'
require 'event_commenter'

module API
  module Concern
    module Comments
      extend ActiveSupport::Concern

      included do

        segment :events do
          route_param :event_id do
            namespace :comments do

              before do
                authenticate_user!
              end

              desc 'list comments of an event'
              params do
                requires :access_token, type: String, desc: 'user access token'
                optional :pivot_as_unix_timestamp, type: Float, desc: 'Comment timestamp pivot as unix format(fix)'
                optional :dir, type: String, values: %w(older newer), default: 'newer', desc: 'comment direction, whether older or newer than pivot'
                optional :limit, type: Integer, default: 25, desc: 'number of comments returned in a single request'
                optional :force_order, coerce: Virtus::Attribute::Boolean, desc: "if 1 then asc order"
              end
              get '/' do
                begin
                  event = EventManager.new(current_user).find params[:event_id]
                  EventAuthorization.new(event, current_user).authorize :list_comment
                  EventView.new(event.id, current_user).view_comments!
                  dir = { older: '<=', newer: '>=' }
                  pivot = params[:pivot_as_unix_timestamp].blank? ? DateTime.now : Time.at(params[:pivot_as_unix_timestamp])
                  if params[:dir] === 'newer'
                    comments = event.root_comments.where("created_at >= ?", pivot+1.seconds).order('created_at').limit(params[:limit]).to_a
                    if comments.size > 0 && event.root_comments.size >= params[:limit] && comments.size < params[:limit]
                      comments = event.root_comments.where("created_at <= ?", DateTime.now).order('created_at desc').limit(params[:limit]).to_a
                    else
                      comments = comments.sort_by{|c| c.created_at}.reverse!
                    end
                  else
                    if params[:force_order].present? && params[:force_order]
                      comments = event.root_comments.order('created_at').limit(params[:limit]).to_a
                    else
                      comments = event.root_comments.where("created_at <= ?", pivot).order('created_at desc').limit(params[:limit]).to_a
                    end
                  end
                  success! comments.as_api_response(:light_listing), 200
                rescue Pundit::NotAuthorizedError
                  success! [], 200
                rescue => e
                  throw_error! 403, e.class, e.message
                end
              end

              desc "Create comment for an event"
              params do
                requires :access_token, type: String, desc: 'user access token'
                requires :comment, type: String, desc: 'user comment'
              end
              post '/' do
                begin
                  event = EventManager.new(current_user).find params[:event_id]
                  EventAuthorization.new(event, current_user).authorize :create_comment
                  comment = EventCommenter.new(current_user).comment!(event, params[:comment])
                  after_save comment, 201, 'comment created'
                rescue => e
                  throw_error! 403, e.class, e.message
                end
              end

              desc "Update comment for an event"
              params do
                requires :access_token, type: String, desc: 'user access token'
                requires :comment, type: String, desc: 'user comment'
              end
              put "/:id" do
                begin
                  event = EventManager.new(current_user).find params[:event_id]
                  comment = event.root_comments.find params[:id]
                  EventAuthorization.new(event, current_user).with_object(comment).authorize :update_comment
                  comment.update_attributes declared_api_params
                  after_save comment, 200, "comment updated"
                rescue => e
                  throw_error! 403, e.class, e.message
                end
              end

              desc "Hide comment for an event"
              params do
                requires :access_token, type: String, desc: 'user access token'
              end
              post "/:id/hide" do
                begin
                  event = EventManager.new(current_user).find params[:event_id]
                  comment = event.root_comments.find params[:id]
                  EventAuthorization.new(event, current_user).with_object(comment).authorize :hide_comment
                  comment.hide = true
                  comment.hidden_by_user = current_user
                  comment.save!
                  after_save comment, 200, "comment hidded"
                rescue => e
                  throw_error! 403, e.class, e.message
                end
              end

              desc "Show hidden comment for an event"
              params do
                requires :access_token, type: String, desc: 'user access token'
              end
              delete "/:id/hide" do
                begin
                  event = EventManager.new(current_user).find params[:event_id]
                  comment = event.root_comments.find params[:id]
                  EventAuthorization.new(event, current_user).with_object(comment).authorize :show_hidden_comment
                  comment.hide = false
                  comment.hidden_by_user = nil
                  comment.save!
                  after_save comment, 200, "hidden comment was show"
                rescue => e
                  throw_error! 403, e.class, e.message
                end
              end

              desc "Delete comment for an event"
              params do
                requires :access_token, type: String, desc: 'user access token'
              end
              delete "/:id" do
                begin
                  event = EventManager.new(current_user).find params[:event_id]
                  comment = event.root_comments.find params[:id]
                  EventAuthorization.new(event, current_user).with_object(comment).authorize :delete_comment
                  comment.destroy
                  after_save comment, 200, "comment deleted"
                rescue => e
                  throw_error! 403, e.class, e.message
                end
              end

            end
          end
        end
      end
    end
  end
end
