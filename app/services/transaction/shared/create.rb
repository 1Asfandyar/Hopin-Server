# frozen_string_literal: true

class Transaction::Shared::Create < ApplicationService
  include Transaction::Helpers

  def call(paid_by_user:, shared_by_users:, split_method:, title:, amount_cents:,
           account:, category:, transaction_date:, note: nil, currency: nil)
    @paid_by_user     = paid_by_user
    @shared_by_users  = shared_by_users
    @split_method     = split_method
    @title            = title
    @amount_cents     = amount_cents
    @account          = account
    @category         = category
    @transaction_date = transaction_date
    @note             = note
    @currency         = currency

    persist
  end

  private

  attr_reader :paid_by_user, :shared_by_users, :split_method, :title, :amount_cents,
              :account, :category, :transaction_date, :note, :currency, :transaction

  def persist
    debt_result = nil

    ActiveRecord::Base.transaction do
      @transaction = create_transaction!
      splits       = calculate_splits
      create_splits!(splits)
      debt_result  = update_debts!(splits)
      raise ActiveRecord::Rollback if debt_result.failure?
    end

    return debt_result if debt_result&.failure?

    Success(transaction)
  rescue ActiveRecord::RecordInvalid => e
    Failure(errors: e.record.errors.to_hash)
  end

  def create_transaction!
    txn = Transaction.create!(
      user:             paid_by_user,
      transaction_type: :expense,
      visibility_type:  :shared,
      title:            title,
      amount_cents:     amount_cents,
      account:          account,
      category:         category,
      transaction_date: transaction_date,
      note:             note,
      currency:         currency || account.currency
    )
    update_account_balance(account: account, transaction_type: :expense, amount_cents: amount_cents)
    txn
  end

  def calculate_splits
    Transaction::Splits::Calculator.calculate(
      method:       split_method,
      amount_cents: amount_cents,
      user_ids:     shared_by_users.map(&:id)
    )
  end

  def create_splits!(splits)
    splits.each do |split|
      transaction.transaction_splits.create!(
        user_id:           split[:user_id],
        split_method:      split[:split_method],
        owed_amount_cents: split[:owed_amount_cents],
        allocation_value:  split[:allocation_value]
      )
    end
  end

  def update_debts!(splits)
    splits.each do |split|
      next if split[:user_id] == paid_by_user.id

      debtor = shared_by_users.find { |u| u.id == split[:user_id] }
      result = Debts::UpdateBalance.call(
        debtor_user:  debtor,
        payer_user:   paid_by_user,
        amount_cents: split[:owed_amount_cents]
      )

      return result if result.failure?
    end

    Success()
  end
end
