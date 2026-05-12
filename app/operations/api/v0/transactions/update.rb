module Api::V0::Transactions
  class Update
    include Api::V0::ApplicationOperation

    ALLOWED_TYPES = Transaction.transaction_types.keys.freeze

    class Contract < Api::V0::ApplicationContract
      params do
        required(:id).filled(:integer)
        optional(:title).filled(:string)
        optional(:transaction_type).filled(:string)
        optional(:amount_cents).filled(:integer)
        optional(:account_id).filled(:integer)
        optional(:category_id).filled(:integer)
        optional(:transaction_date).filled(:string)
        optional(:note).maybe(:string)
        optional(:currency_id).filled(:integer)
      end

      rule(:transaction_type) do
        next unless value
        key.failure("must be one of #{ALLOWED_TYPES.join(', ')}") unless ALLOWED_TYPES.include?(value)
      end

      rule(:amount_cents) do
        next unless value
        key.failure("must be greater than 0") if value <= 0
      end

      rule(:transaction_date) do
        next unless value
        Time.parse(value)
      rescue ArgumentError, TypeError
        key.failure("must be a valid ISO 8601 datetime")
      end
    end

    def call(params, current_user:)
      @params       = params
      @current_user = current_user

      yield find_transaction
      yield find_account
      yield find_category
      yield find_currency
      yield persist

      Success(
        success: true,
        transaction: Api::V0::TransactionSerializer.render_as_hash(transaction)
      )
    end

    private

    attr_reader :current_user, :params, :transaction, :account, :category, :currency

    def find_transaction
      @transaction = current_user.transactions.find_by(id: params[:id])
      @transaction ? Success() : Failure(:not_found)
    end

    def find_account
      return Success() unless params.key?(:account_id)
      @account = current_user.accounts.find_by(id: params[:account_id])
      @account ? Success() : Failure(:not_found)
    end

    def find_category
      return Success() unless params.key?(:category_id)
      @category = current_user.categories.find_by(id: params[:category_id])
      @category ? Success() : Failure(:not_found)
    end

    def find_currency
      return Success() unless params.key?(:currency_id)
      @currency = Currency.find_by(id: params[:currency_id])
      @currency ? Success() : Failure(:not_found)
    end

    def persist
      service_attrs = {}
      service_attrs[:title]            = params[:title]                        if params.key?(:title)
      service_attrs[:transaction_type] = params[:transaction_type]             if params.key?(:transaction_type)
      service_attrs[:amount_cents]     = params[:amount_cents]                 if params.key?(:amount_cents)
      service_attrs[:account]          = account                               if account
      service_attrs[:category]         = category                              if category
      service_attrs[:currency]         = currency                              if currency
      service_attrs[:transaction_date] = Time.parse(params[:transaction_date]) if params.key?(:transaction_date)
      service_attrs[:note]             = params[:note]                         if params.key?(:note)

      result = Transaction::Personal::Update.call(transaction: transaction, **service_attrs)
      if result.success?
        @transaction = result.value!
        Success()
      else
        Failure(errors: result.failure[:errors])
      end
    end
  end
end
