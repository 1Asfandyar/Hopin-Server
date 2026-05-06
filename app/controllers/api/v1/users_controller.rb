module Api
  module V1
    class UsersController < ApiController
      before_action :require_current_user!

      resource_description do
        short 'Users management'
        description 'Manage user accounts and authentication'
        api_version 'v1'
      end

      api :GET, '/v1/users', 'List all users'
      def index
        Api::V1::Users::Index.call(params.to_unsafe_h, current_user: current_user) do |result|
          result.success { |data| render json: data, status: :ok }
          result.failure(:forbidden) { forbidden_response }
          result.failure { |errors| unprocessable_entity(errors) }
        end
      end

      api :GET, '/v1/users/:id', 'Get user details'
      param :id, Integer, required: true, description: 'User ID'
      def show
        Api::V1::Users::Show.call(params.to_unsafe_h, current_user: current_user) do |result|
          result.success { |data| render json: data, status: :ok }
          result.failure(:not_found) { not_found_response }
          result.failure(:forbidden) { forbidden_response }
          result.failure { |errors| unprocessable_entity(errors) }
        end
      end

      api :POST, '/v1/users', 'Create a new user'
      param :user, Hash, required: true, description: 'User attributes' do
        param :email, String, required: true, description: 'User email'
        param :password, String, required: true, description: 'User password'
        param :password_confirmation, String, required: true, description: 'Password confirmation'
        param :role, String, description: 'User role'
      end
      def create
        Api::V1::Users::Create.call(params.to_unsafe_h, current_user: current_user) do |result|
          result.success { |data| render json: data, status: :created }
          result.failure(:forbidden) { forbidden_response }
          result.failure { |errors| unprocessable_entity(errors) }
        end
      end

      api :PATCH, '/v1/users/:id', 'Update user'
      param :id, Integer, required: true, description: 'User ID'
      param :user, Hash, description: 'User attributes' do
        param :email, String, description: 'User email'
        param :password, String, description: 'User password'
      end
      def update
        Api::V1::Users::Update.call(params.to_unsafe_h, current_user: current_user) do |result|
          result.success { |data| render json: data, status: :ok }
          result.failure(:not_found) { not_found_response }
          result.failure(:forbidden) { forbidden_response }
          result.failure { |errors| unprocessable_entity(errors) }
        end
      end

      api :DELETE, '/v1/users/:id', 'Delete user'
      param :id, Integer, required: true, description: 'User ID'
      def destroy
        Api::V1::Users::Destroy.call(params.to_unsafe_h, current_user: current_user) do |result|
          result.success { |data| render json: data, status: :ok }
          result.failure(:not_found) { not_found_response }
          result.failure(:forbidden) { forbidden_response }
          result.failure { |errors| unprocessable_entity(errors) }
        end
      end
    end
  end
end
