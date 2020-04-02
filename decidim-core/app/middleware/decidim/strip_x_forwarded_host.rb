# frozen_string_literal: true

module Decidim
  class StripXForwardedHost
    def initialize(app)
      @app = app
    end

    def call(env)
      env["HTTP_X_FORWARDED_HOST"] = nil
      @app.call(env)
    end
  end
end
