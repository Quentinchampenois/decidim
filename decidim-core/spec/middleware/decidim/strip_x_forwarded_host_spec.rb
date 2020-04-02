# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe StripXForwardedHost do
    let(:app) { ->(env) { [200, env, "app"] } }
    let(:forwarded_host) { "something.evil.org" }
    let(:env) { Rack::MockRequest.env_for("https://#{host}/a?foo=bar", "HTTP_X_FORWARDED_HOST" => forwarded_host) }
    let(:host) { "city.domain.org" }
    let(:middleware) { described_class.new(app) }

    it "strips the header" do
      _code, new_env = middleware.call(env)

      expect(new_env["HTTP_X_FORWARDED_HOST"]).to eq(nil)
    end
  end
end
