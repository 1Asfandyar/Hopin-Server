FactoryBot.define do
  factory :debt do
    amount_cents { 1000 }
    association :from_user, factory: :user
    association :to_user,   factory: :user
  end
end
