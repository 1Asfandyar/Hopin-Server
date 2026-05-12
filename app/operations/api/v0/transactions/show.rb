module Api::V0::Transactions
  class Show
    include Api::V0::ApplicationOperation

    class Contract < Api::V0::ApplicationContract
      params do
        required(:id).filled(:integer)
      end
    end

    def call(params, current_user:)
      @params       = params
      @current_user = current_user
      @transaction  = current_user.transactions.find_by(id: params[:id])

      return Failure(:not_found) unless transaction

      yield authorize?

      Success(
        success: true,
        transaction: Api::V0::TransactionSerializer.render_as_hash(transaction)
      )
    end

    private

    attr_reader :current_user, :params, :transaction

    def authorize?
      TransactionPolicy.new(current_user, transaction).show? ? Success() : Failure(:forbidden)
    end
  end
end
