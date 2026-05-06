module Api
  module V1
    class ApiController < ActionController::API
      include Apipie::DSL
      include Pundit::Authorization

      rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
      rescue_from Pundit::NotAuthorizedError, with: :forbidden_response
      rescue_from StandardError, with: :handle_standard_error

      private

      def require_current_user!
        unauthorized_response unless current_user
      end

      def unauthorized_response(message = 'You are unauthorized to view this resource')
        render json: error_payload(message), status: :unauthorized
      end

      def forbidden_response(message = 'You do not have access to perform this action')
        render json: error_payload(message), status: :forbidden
      end

      def not_found_response(message = 'The requested resource does not exist')
        render json: error_payload(message), status: :not_found
      end

      def unprocessable_entity(errors)
        render json: normalize_errors(errors), status: :unprocessable_entity
      end

      def handle_standard_error(exception)
        Rails.logger.error(exception.full_message)
        render json: error_payload('Something went wrong'), status: :internal_server_error
      end

      def error_payload(message)
        { errors: [{ base: [message] }] }
      end

      def normalize_errors(errors)
        return errors if errors.is_a?(Hash) && errors.key?(:errors)

        { errors: Array(errors) }
      end
    end
  end
end
