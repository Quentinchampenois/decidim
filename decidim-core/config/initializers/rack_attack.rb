# frozen_string_literal: true

if (ENV.fetch("ENABLE_RACK_ATTACK", nil) == "1") || Rails.env.production? || Rails.env.test?
  require "rack/attack"

  Rails.application.configure do |config|
    config.middleware.use Rack::Attack
  end

  ActiveSupport::Reloader.to_prepare do
    Rack::Attack.blocklist("block all access to system") do |request|
      # Requests are blocked if the return value is truthy
      if request.path.start_with?("/system")
        next if Decidim.system_accesslist_ips.blank?

        # returns true if request.ip is not included in system access list
        Decidim.system_accesslist_ips.select do |ip_address|
          IPAddr.new(ip_address).include?(IPAddr.new(request.ip))
        end.empty?
      end
    end

    unless Rails.env.test?
      Rack::Attack.throttle(
        "requests by ip",
        limit: Decidim.throttling_max_requests,
        period: Decidim.throttling_period,
        &:ip
      )

      # Throttle login attempts for a given email parameter to 6 reqs/minute
      # Return the email as a discriminator on POST /users/sign_in requests
      Rack::Attack.throttle("limit logins per email", limit: 5, period: 60.seconds) do |request|
        request.params["user"]["email"] if request.path == "/users/sign_in" && request.post?
      end

      # Throttle login attempts for a given email parameter to 6 reqs/minute
      # Return the email as a discriminator on POST /users/sign_in requests
      Rack::Attack.throttle("limit password recovery attempts per email", limit: 5, period: 60.seconds) do |request|
        request.params["user"]["email"] if request.path == "/users/password" && request.post?
      end
    end
  end
end
