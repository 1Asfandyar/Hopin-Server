# frozen_string_literal: true

class Transaction::Transfer::Destroy < ApplicationService
  include Transaction::Helpers

  def call(transaction:)
    @transaction = transaction
    execute
  end

  private

  attr_reader :transaction

  def execute
    ActiveRecord::Base.transaction do
      revert_transfer_balance(
        from_account: transaction.account,
        to_account:   transaction.transfer_account,
        amount_cents: transaction.amount_cents
      )
      transaction.destroy!
    end
    Success(true)
  rescue ActiveRecord::RecordNotDestroyed => e
    Failure(errors: { base: [ e.message ] })
  end
end
