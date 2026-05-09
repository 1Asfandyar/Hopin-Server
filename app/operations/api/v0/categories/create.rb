module Api::V0::Categories
  class Create
    include Api::V0::ApplicationOperation

    VALID_TYPES = %w[expense income].freeze

    class Contract < Api::V0::ApplicationContract
      params do
        required(:name).filled(:string)
        required(:category_type).filled(:string)
      end

      rule(:category_type) do
        key.failure("must be expense or income") unless %w[expense income].include?(value)
      end
    end

    def call(params, current_user:)
      @current_user = current_user
      validated     = yield validate_contract(category_params(params))
      @attributes   = validated

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
      CategoryPolicy.new(current_user, Category.new).create? ? Success() : Failure(:forbidden)
    end

    def persist
      @category = Category.new(attributes.merge(user: current_user))
      category.save ? Success(category) : Failure(errors: category.errors.to_hash)
    end
  end
end
