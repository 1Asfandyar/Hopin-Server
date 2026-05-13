module Api::V0::Transactions
  class Create
    include Api::V0::ApplicationOperation

    ALLOWED_TYPES       = Transaction.transaction_types.keys.freeze
    SUPPORTED_SPLITS    = Transaction::Splits::Calculator::SUPPORTED.freeze

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

        # shared expense fields
        optional(:paid_by).maybe(:integer)
        optional(:shared_by).maybe(:array)
        optional(:split_method).maybe(:string)
      end

      rule(:transaction_type) do
        key.failure("must be one of #{ALLOWED_TYPES.join(', ')}") unless ALLOWED_TYPES.include?(value)
      end

      rule(:amount_cents) do
        key.failure("must be greater than 0") if value <= 0
      end

      rule(:transaction_date) do
        next if value.nil?

        Time.parse(value)
      rescue ArgumentError, TypeError
        key.failure("must be a valid ISO 8601 datetime")
      end

      # --- personal / shared expense ---

      rule(:account_id) do
        next if values[:transaction_type] == "transfer"
        key.failure("is required") if value.nil?
      end

      rule(:category_id) do
        next if values[:transaction_type] == "transfer"
        key.failure("is required") if value.nil?
      end

      # --- transfer ---

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

      # --- shared expense only ---

      rule(:shared_by) do
        next unless values[:transaction_type] == "expense" && !value.nil?
        key.failure("must have at least one user") if value.empty?
        key.failure("must be an array of integers") if value.any? { |v| !v.is_a?(Integer) }
      end

      rule(:paid_by) do
        next unless values[:transaction_type] == "expense" && !values[:shared_by].nil? && values[:shared_by].any?
        key.failure("is required for shared expense") if value.nil?
      end

      rule(:split_method) do
        next unless values[:transaction_type] == "expense" && !values[:shared_by].nil? && values[:shared_by].any?
        key.failure("is required for shared expense") if value.nil?
        next if value.nil?
        key.failure("must be one of: #{SUPPORTED_SPLITS.join(', ')}") unless SUPPORTED_SPLITS.include?(value)
      end
    end

    def call(params, current_user:)
      @params       = params
      @current_user = current_user

      if transfer?
        yield find_from_account
        yield find_to_account
      elsif shared_expense?
        yield find_paid_by_user
        yield find_account_for_payer
        yield find_category_for_payer
        yield find_shared_by_users
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
                :category, :currency, :transaction, :paid_by_user, :shared_by_users

    def transfer?
      params[:transaction_type] == "transfer"
    end

    def shared_expense?
      params[:transaction_type] == "expense" && params[:shared_by].present?
    end

    # --- finders for personal expense ---

    def find_account
      @account = current_user.accounts.find_by(id: params[:account_id])
      @account ? Success() : Failure(:not_found)
    end

    def find_category
      @category = current_user.categories.find_by(id: params[:category_id])
      @category ? Success() : Failure(:not_found)
    end

    # --- finders for transfer ---

    def find_from_account
      @from_account = current_user.accounts.find_by(id: params[:from_account_id])
      @from_account ? Success() : Failure(:not_found)
    end

    def find_to_account
      @to_account = current_user.accounts.find_by(id: params[:to_account_id])
      @to_account ? Success() : Failure(:not_found)
    end

    # --- finders for shared expense ---

    def find_paid_by_user
      @paid_by_user = User.find_by(id: params[:paid_by])
      @paid_by_user ? Success() : Failure(:not_found)
    end

    def find_account_for_payer
      @account = paid_by_user.accounts.find_by(id: params[:account_id])
      @account ? Success() : Failure(:not_found)
    end

    def find_category_for_payer
      @category = paid_by_user.categories.find_by(id: params[:category_id])
      @category ? Success() : Failure(:not_found)
    end

    def find_shared_by_users
      @shared_by_users = User.where(id: params[:shared_by]).to_a
      missing = params[:shared_by] - @shared_by_users.map(&:id)
      missing.empty? ? Success() : Failure(errors: { shared_by: [ "contains unknown user IDs: #{missing.join(', ')}" ] })
    end

    # --- currency (all types) ---

    def find_currency
      return Success() unless params[:currency_id]

      @currency = Currency.find_by(id: params[:currency_id])
      @currency ? Success() : Failure(:not_found)
    end

    # --- persistence ---

    def persist
      if transfer?
        persist_transfer
      elsif shared_expense?
        persist_shared_expense
      else
        persist_personal
      end
    end

    def persist_transfer
      result = Transaction::Transfer::Create.call(
        user:             current_user,
        title:            params[:title],
        amount_cents:     params[:amount_cents],
        from_account:     from_account,
        to_account:       to_account,
        transaction_date: parse_date,
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
        transaction_date: parse_date,
        note:             params[:note],
        currency:         currency
      )
      handle_service_result(result)
    end

    def persist_shared_expense
      result = Transaction::Shared::Create.call(
        paid_by_user:     paid_by_user,
        shared_by_users:  shared_by_users,
        split_method:     params[:split_method],
        title:            params[:title],
        amount_cents:     params[:amount_cents],
        account:          account,
        category:         category,
        transaction_date: parse_date,
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

    def parse_date
      params[:transaction_date] ? Time.parse(params[:transaction_date]) : Time.current
    end
  end
end
