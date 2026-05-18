module Api::V0::Groups
  class Index
    include Api::V0::ApplicationOperation

    class Contract < Api::V0::ApplicationContract
      params do
        required(:kind).filled(:string)
      end

      rule(:kind) do
        key.failure("must be one of: custom, friends") unless Group.kinds.key?(value)
      end
    end

    def call(params, current_user:)
      @params = yield validate_contract(params.slice(:kind))
      @current_user = current_user

      Success(
        success: true,
        groups: Api::V0::GroupSerializer.render_as_hash(groups)
      )
    end

    private

    attr_reader :current_user, :params

    def groups
      scope = current_user.groups.includes(:groups_users, :users)
      scope.public_send(params[:kind])
    end
  end
end
