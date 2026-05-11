module Api::V0::Accounts
  class Create
    include Api::V0::ApplicationOperation

    class Contract < Api::V0::ApplicationContract
      params do
        required(:name).filled(:string)
        optional(:current_balance_cents).maybe(:integer)
        optional(:initial_balance_cents).maybe(:integer)
        optional(:currency_id).maybe(:integer)
      end
    end

    def call(params, current_user:)
      @params       = params
      @current_user = current_user

      yield authorize?
      yield persist

      Success(
        success: true,
        account: Api::V0::AccountSerializer.render_as_hash(account)
      )
    end

    private

    attr_reader :current_user, :params, :account

    def authorize?
      AccountPolicy.new(current_user, Account.new).create? ? Success() : Failure(:forbidden)
    end

    def validate_currency
      return Success() if params[:currency_id].nil?
      Currency.exists?(id: params[:currency_id]) ? Success() : Failure(:invalid_currency)
    end

    def persist
      @account = Account.new(account_params)
      account.save ? Success(account) : Failure(errors: account.errors.to_hash)
    end

    def account_params
      {
        name: params[:name],
        current_balance_cents: params[:current_balance_cents] || 0,
        initial_balance_cents: params[:initial_balance_cents] || 0,
        currency_id: params[:currency_id] || Currency.find_by(code: "USD")&.id,
        user: current_user
      }
    end
  end
end
