module Api
  module V1
    class AuthController < ApiController
      def create
        user = User.find_for_authentication(email: login_params[:email])

        return unauthorized_response('Invalid email or password') unless user&.valid_password?(login_params[:password])

        token, payload = Warden::JWTAuth::UserEncoder.new.call(user, JWT_SCOPE, JWT_AUDIENCE)
        response.set_header('Authorization', "Bearer #{token}")

        render json: {
          success: true,
          token: token,
          expires_at: Time.zone.at(payload['exp']),
          user: Api::V1::UserSerializer.render_as_hash(user, view: :show)
        }, status: :ok
      end

      def destroy
        token = bearer_token

        return unauthorized_response unless token

        Warden::JWTAuth::TokenRevoker.new.call(token)

        render json: { success: true, message: 'Logged out successfully' }, status: :ok
      rescue JWT::DecodeError
        unauthorized_response
      end

      private

      def login_params
        params.fetch(:user, params).permit(:email, :password)
      end
    end
  end
end
