module Api::V0::Auth
  class Signup
    include Api::V0::ApplicationOperation

    class Contract < Api::V0::ApplicationContract
      params do
        required(:full_name).filled(:string)
        required(:mobile_number).filled(:string)
        required(:email).filled(:string)
        required(:password).filled(:string)
        optional(:password_confirmation).maybe(:string)
      end

      rule(:email).validate(:email_format)
    end

    def call(params)
      params = yield validate_contract(params)
      user = User.new(params.slice(:full_name, :mobile_number, :email, :password, :password))

      yield save_user(user)

      Success(auth_payload(user))
    end

    private

    def save_user(user)
      user.save ? Success(user) : Failure(errors: user.errors.to_hash)
    end

    def auth_payload(user)
      token, payload = Warden::JWTAuth::UserEncoder.new.call(
        user,
        Api::V0::ApiController::JWT_SCOPE,
        Api::V0::ApiController::JWT_AUDIENCE
      )

      {
        success: true,
        token: token,
        authorization: "Bearer #{token}",
        expires_at: Time.zone.at(payload["exp"]),
        user: Api::V0::UserSerializer.render_as_hash(user)
      }
    end
  end
end
