module Api
  module V1
    class UserSerializer
      class << self
        def render_as_hash(resource, view: :show)
          if resource.respond_to?(:map)
            resource.map { |user| user_hash(user, view: view) }
          else
            user_hash(resource, view: view)
          end
        end

        private

        def user_hash(user, view:)
          {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at,
            updated_at: user.updated_at
          }
        end
      end
    end
  end
end
