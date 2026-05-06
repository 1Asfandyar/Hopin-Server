module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      resource_description do
        short 'Users management'
        description 'Manage user accounts and authentication'
        api_version 'v1'
      end

      api :GET, '/v1/users', 'List all users'
      def index
        @users = User.all
        json_response(@users)
      end

      api :GET, '/v1/users/:id', 'Get user details'
      param :id, Integer, required: true, description: 'User ID'
      def show
        @user = User.find(params[:id])
        json_response(@user)
      end

      api :POST, '/v1/users', 'Create a new user'
      param :user, Hash, required: true, description: 'User attributes' do
        param :email, String, required: true, description: 'User email'
        param :password, String, required: true, description: 'User password'
        param :password_confirmation, String, required: true, description: 'Password confirmation'
        param :role, String, description: 'User role'
      end
      def create
        @user = User.new(user_params)
        if @user.save
          json_response(@user, 201)
        else
          json_response({ errors: @user.errors.full_messages }, 422)
        end
      end

      api :PATCH, '/v1/users/:id', 'Update user'
      param :id, Integer, required: true, description: 'User ID'
      param :user, Hash, description: 'User attributes' do
        param :email, String, description: 'User email'
        param :password, String, description: 'User password'
      end
      def update
        @user = User.find(params[:id])
        if @user.update(user_params)
          json_response(@user)
        else
          json_response({ errors: @user.errors.full_messages }, 422)
        end
      end

      api :DELETE, '/v1/users/:id', 'Delete user'
      param :id, Integer, required: true, description: 'User ID'
      def destroy
        @user = User.find(params[:id])
        @user.destroy
        json_response({ message: 'User deleted' })
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :role)
      end
    end
  end
end
