module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend
      
      # Rate limiting for API endpoints
      rate_limit to: 100, within: 1.minute, 
                 by: -> { request.authorization&.split(' ')&.last }, 
                 with: -> { render_rate_limit_exceeded }
      
      before_action :authenticate_api_user!
      before_action :set_tenant
      before_action :record_api_usage
      after_action :set_rate_limit_headers
      
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      
      private
      
      def authenticate_api_user!
        @current_api_user = authenticate_with_http_token do |token, options|
          User.find_by_api_token(token)
        end
        
        unless @current_api_user
          render json: { error: 'Invalid or missing API token' }, status: :unauthorized
        end
      end
      
      def set_tenant
        Current.tenant = @current_api_user.tenant if @current_api_user
      end
      
      def record_api_usage
        @current_api_user.record_api_request! if @current_api_user
      end
      
      def current_api_user
        @current_api_user
      end
      
      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end
      
      def unprocessable_entity(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
      end
      
      # Pagination helpers
      def pagy_metadata(pagy)
        {
          current_page: pagy.page,
          next_page: pagy.next,
          prev_page: pagy.prev,
          total_pages: pagy.pages,
          total_count: pagy.count,
          per_page: pagy.limit
        }
      end
      
      # Rate limiting helpers
      def render_rate_limit_exceeded
        render json: {
          error: 'rate_limit_exceeded',
          message: 'Too many requests. Please retry after some time.'
        }, status: :too_many_requests
      end
      
      def set_rate_limit_headers
        if request.authorization.present?
          response.headers['X-RateLimit-Limit'] = '100'
          # Rails 8 doesn't expose remaining count directly, so we'll set a placeholder
          # In production, you might want to implement a custom solution to track this
          response.headers['X-RateLimit-Reset'] = 1.minute.from_now.to_i.to_s
        end
      end
    end
  end
end