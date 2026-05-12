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
        optional(:from_account_id).filled(:integer)
        optional(:to_account_id).filled(:integer)
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

      rule(:from_account_id, :to_account_id) do
        next unless value && values[:to_account_id]
        key(:to_account_id).failure("must be different from from_account_id") if value == values[:to_account_id]
      end
    end

    def call(params, current_user:)
      @params       = params
      @current_user = current_user

      yield find_transaction
      yield find_account
      yield find_from_account
      yield find_to_account
      yield find_category
      yield find_currency
      yield validate_transfer_params
      yield persist

      Success(
        success: true,
        transaction: Api::V0::TransactionSerializer.render_as_hash(transaction)
      )
    end

    private

    attr_reader :current_user, :params, :transaction, :account,
                :from_account, :to_account, :category, :currency

    def find_transaction
      @transaction = current_user.transactions.find_by(id: params[:id])
      @transaction ? Success() : Failure(:not_found)
    end

    def find_account
      return Success() unless params.key?(:account_id)
      @account = current_user.accounts.find_by(id: params[:account_id])
      @account ? Success() : Failure(:not_found)
    end

    def find_from_account
      return Success() unless params.key?(:from_account_id)
      @from_account = current_user.accounts.find_by(id: params[:from_account_id])
      @from_account ? Success() : Failure(:not_found)
    end

    def find_to_account
      return Success() unless params.key?(:to_account_id)
      @to_account = current_user.accounts.find_by(id: params[:to_account_id])
      @to_account ? Success() : Failure(:not_found)
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

    def validate_transfer_params
      new_type = (params[:transaction_type] || transaction.transaction_type).to_sym
      return Success() unless new_type == :transfer

      effective_to_account = to_account || transaction.transfer_account
      if effective_to_account.nil?
        return Failure(errors: { to_account_id: ["is required for transfer"] })
      end

      effective_from_id = (from_account || transaction.account).id
      effective_to_id   = effective_to_account.id
      if effective_from_id == effective_to_id
        return Failure(errors: { to_account_id: ["must be different from from_account_id"] })
      end

      Success()
    end

    def persist
      new_type = (params[:transaction_type] || transaction.transaction_type).to_sym
      uses_transfer = transaction.transfer? || new_type == :transfer
      uses_transfer ? update_as_transfer : update_as_personal
    end

    def update_as_transfer
      service_attrs = build_common_attrs
      service_attrs[:from_account] = from_account if from_account
      service_attrs[:to_account]   = to_account   if to_account

      result = Transaction::Transfer::Update.call(transaction: transaction, **service_attrs)
      handle_service_result(result)
    end

    def update_as_personal
      service_attrs = build_common_attrs
      service_attrs[:account] = account if account

      result = Transaction::Personal::Update.call(transaction: transaction, **service_attrs)
      handle_service_result(result)
    end

    def build_common_attrs
      attrs = {}
      attrs[:title]            = params[:title]                        if params.key?(:title)
      attrs[:transaction_type] = params[:transaction_type]             if params.key?(:transaction_type)
      attrs[:amount_cents]     = params[:amount_cents]                 if params.key?(:amount_cents)
      attrs[:category]         = category                              if category
      attrs[:currency]         = currency                              if currency
      attrs[:transaction_date] = Time.parse(params[:transaction_date]) if params.key?(:transaction_date)
      attrs[:note]             = params[:note]                         if params.key?(:note)
      attrs
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
