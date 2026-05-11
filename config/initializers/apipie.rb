class RedcarpetMarkup
  def initialize
    require "redcarpet"
    @renderer = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(filter_html: false),
      fenced_code_blocks: true,
      no_intra_emphasis: true
    )
  end

  def to_html(text)
    @renderer.render(text)
  end
end

Apipie.configure do |config|
  config.app_name                = "Hopin API"
  config.app_info                = "Hopin personal finance API. All endpoints require a JWT Bearer token in the Authorization header."
  config.api_base_url            = "/api"
  config.doc_base_url            = "/apipie"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
  config.default_version         = "v0"
  config.markup                  = RedcarpetMarkup.new
  config.validate                = false
end
