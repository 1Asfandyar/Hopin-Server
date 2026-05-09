module Api::V0::Categories
  class Update
    include Api::V0::ApplicationOperation

    class Contract < Api::V0::ApplicationContract
      params do
        optional(:name).maybe(:string)
        optional(:category_type).maybe(:string)
      end

      rule(:category_type) do
        next unless key? && value
        key.failure("must be expense or income") unless %w[expense income].include?(value)
      end
    end

    def call(params, current_user:)
      @current_user = current_user
      @id           = (params[:id] || params["id"]).to_i
      validated     = yield validate_contract(category_params(params))
      @attributes   = validated.compact

      @category = Category.find_by(id: @id)
      return Failure(:not_found) unless category

      yield authorize
      yield persist

      Success(
        success: true,
        category: Api::V0::CategorySerializer.render_as_hash(category)
      )
    end

    private

    attr_reader :current_user, :attributes, :category

    def category_params(params)
      params.fetch(:category, params.fetch("category", {}))
    end

    def authorize
      CategoryPolicy.new(current_user, category).update? ? Success() : Failure(:forbidden)
    end

    def persist
      category.update(attributes) ? Success(category) : Failure(errors: category.errors.to_hash)
    end
  end
end
