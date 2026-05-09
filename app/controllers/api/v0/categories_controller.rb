module Api::V0
  class CategoriesController < ApiController
    def index
      Api::V0::Categories::Index.call(params.to_unsafe_h, current_user: current_user) do |result|
        result.success { |data| render json: data, status: :ok }
        result.failure(:forbidden) { forbidden_response }
        result.failure { |errors| unprocessable_entity(errors) }
      end
    end

    def show
      Api::V0::Categories::Show.call(params.to_unsafe_h, current_user: current_user) do |result|
        result.success { |data| render json: data, status: :ok }
        result.failure(:not_found) { not_found_response }
        result.failure(:forbidden) { forbidden_response }
        result.failure { |errors| unprocessable_entity(errors) }
      end
    end

    def create
      Api::V0::Categories::Create.call(params.to_unsafe_h, current_user: current_user) do |result|
        result.success { |data| render json: data, status: :created }
        result.failure(:forbidden) { forbidden_response }
        result.failure { |errors| unprocessable_entity(errors) }
      end
    end

    def update
      Api::V0::Categories::Update.call(params.to_unsafe_h, current_user: current_user) do |result|
        result.success { |data| render json: data, status: :ok }
        result.failure(:not_found) { not_found_response }
        result.failure(:forbidden) { forbidden_response }
        result.failure { |errors| unprocessable_entity(errors) }
      end
    end

    def destroy
      Api::V0::Categories::Destroy.call(params.to_unsafe_h, current_user: current_user) do |result|
        result.success { render json: { success: true }, status: :ok }
        result.failure(:not_found) { not_found_response }
        result.failure(:forbidden) { forbidden_response }
        result.failure { |errors| unprocessable_entity(errors) }
      end
    end
  end
end
