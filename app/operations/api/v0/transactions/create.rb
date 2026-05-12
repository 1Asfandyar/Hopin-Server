module Api::V0::Transactions
  class Create
    include Api::V0::ApplicationOperation

    ALLOWED_TYPES = Transaction.transaction_types.keys.freeze

    class Contract < Api::V0::ApplicationContract
      params do
        required(:title).filled(:string)
        required(:transaction_type).filled(:string)
        required(:amount_cents).filled(:integer)
        optional(:account_id).maybe(:integer)
        optional(:category_id).maybe(:integer)
        optional(:from_account_id).maybe(:integer)
        optional(:to_account_id).maybe(:integer)
        optional(:transaction_date).maybe(:string)
        optional(:note).maybe(:string)
        optional(:currency_id).maybe(:integer)
      end

      rule(:transaction_type) do
        key.failure("must be one of #{ALLOWED_TYPES.join(', ')}") unless ALLOWED_TYPES.include?(value)
      end

      rule(:amount_cents) do
        key.failure("must be greater than 0") if value <= 0
      end

      rule(:transaction_date) do
        Time.parse(value)
      rescue ArgumentError, TypeError
        key.failure("must be a valid ISO 8601 datetime")
      end

      rule(:account_id) do
        next if values[:transaction_type] == "transfer"
        key.failure("is required") if value.nil?
      end

      rule(:category_id) do
        next if values[:transaction_type] == "transfer"
        key.failure("is required") if value.nil?
      end

      rule(:from_account_id) do
        next unless values[:transaction_type] == "transfer"
        key.failure("is required for transfer") if value.nil?
      end

      rule(:to_account_id) do
        next unless values[:transaction_type] == "transfer"
        key.failure("is required for transfer") if value.nil?
      end

      rule(:from_account_id, :to_account_id) do
        next unless value && values[:to_account_id]
        key(:to_account_id).failure("must be different from from_account_id") if value == values[:to_account_id]
      end
    end

    def call(params, current_user:)
      @params       = params
      @current_user = current_user

      if transfer?
        yield find_from_account
        yield find_to_account
      else
        yield find_account
        yield find_category
      end
      yield find_currency
      yield persist

      Success(
        success: true,
        transaction: Api::V0::TransactionSerializer.render_as_hash(transaction)
      )
    end

    private

    attr_reader :current_user, :params, :account, :from_account, :to_account,
                :category, :currency, :transaction

    def transfer?
      params[:transaction_type] == "transfer"
    end

    def find_account
      @account = current_user.accounts.find_by(id: params[:account_id])
      @account ? Success() : Failure(:not_found)
    end

    def find_from_account
      @from_account = current_user.accounts.find_by(id: params[:from_account_id])
      @from_account ? Success() : Failure(:not_found)
    end

    def find_to_account
      @to_account = current_user.accounts.find_by(id: params[:to_account_id])
      @to_account ? Success() : Failure(:not_found)
    end

    def find_category
      @category = current_user.categories.find_by(id: params[:category_id])
      @category ? Success() : Failure(:not_found)
    end

    def find_currency
      return Success() unless params[:currency_id]
      @currency = Currency.find_by(id: params[:currency_id])
      @currency ? Success() : Failure(:not_found)
    end

    def persist
      transfer? ? persist_transfer : persist_personal
    end

    def persist_transfer
      result = Transaction::Transfer::Create.call(
        user:             current_user,
        title:            params[:title],
        amount_cents:     params[:amount_cents],
        from_account:     from_account,
        to_account:       to_account,
        transaction_date: Time.parse(params[:transaction_date]),
        note:             params[:note],
        currency:         currency
      )
      handle_service_result(result)
    end

    def persist_personal
      result = Transaction::Personal::Create.call(
        user:             current_user,
        title:            params[:title],
        transaction_type: params[:transaction_type],
        amount_cents:     params[:amount_cents],
        account:          account,
        category:         category,
        transaction_date: Time.parse(params[:transaction_date]),
        note:             params[:note],
        currency:         currency
      )
      handle_service_result(result)
    end

    def handle_service_result(result)
      if result.success?
        @transaction = result.value!
        Success()
      else
        Failure(errors: result.failure[:errors])
      end
    end
  end
end
