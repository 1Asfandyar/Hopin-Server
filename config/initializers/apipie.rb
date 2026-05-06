Apipie.configure do |config|
  config.app_name = "Hopin API"
  config.default_version = "v1"
  config.app_info = "API documentation for the Hopin ride sharing backend."
  config.api_base_url = "/api"
  config.doc_base_url = "/apipie"
  config.validate = false
  config.default_locale = "en"
  config.show_all_examples = true
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
end
