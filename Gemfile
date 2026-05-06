source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.11"

gem "rails", "~> 7.0.0"
gem "pg", "~> 1.1"
gem "puma", "~> 5.0"
gem "bootsnap", require: false
gem "rack-cors"
gem "sprockets-rails"
gem "sassc-rails"

# Authentication
gem "devise"
gem "devise-jwt"

# Admin Panel
gem "activeadmin"

# Authorization
gem "pundit"

# Operation pattern
gem "dry-matcher"
gem "dry-monads"
gem "dry-types"
gem "dry-validation"

# Serialization
gem "active_model_serializers"
gem "blueprinter"

# API Documentation
gem "apipie-rails"

# Database
gem "kaminari"
gem "pagy"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "dotenv-rails"
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
end
