module Abstracted
  class Engine < ::Rails::Engine
    # config.autoload_paths << File.expand_path("../concerns", __FILE__)

    config.generators do |g|
      g.test_framework :rspec,
        :fixture => false,
        :fixtures => true,
        :view_specs => false,
        :helper_specs => false,
        :routing_specs => false,
        :controller_specs => true,
        :request_specs => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.assets false
      g.helper false
    end
  end
end
