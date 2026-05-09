module Api::V0::Categories
  class Destroy
    include Api::V0::ApplicationOperation

    def call(params, current_user:)
      @current_user = current_user
      id            = (params[:id] || params["id"]).to_i
      @category     = Category.find_by(id: id)

      return Failure(:not_found) unless category

      yield authorize

      category.destroy

      Success(success: true)
    end

    private

    attr_reader :current_user, :category

    def authorize
      CategoryPolicy.new(current_user, category).destroy? ? Success() : Failure(:forbidden)
    end
  end
end
