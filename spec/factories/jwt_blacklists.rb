FactoryBot.define do
  factory :jwt_blacklist do
    jti { "MyString" }
    exp { "2026-05-06 15:24:27" }
  end
end
