# frozen_string_literal: true

if (ENV.fetch("ENABLE_RACK_ATTACK", nil) == "1") || Rails.env.production? || Rails.env.test?
  require "rack/attack"

  Rack::Attack.enabled = true

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

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

    Rack::Attack.throttle(
      "requests by ip",
      limit: Decidim.throttling_max_requests,
      period: Decidim.throttling_period, &:ip
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

    # Block suspicious requests made for pentesting
    # After 1 forbidden request, block all requests from that IP for 1 hour.
    Rack::Attack.blocklist("fail2ban pentesters") do |req|
      # `filter` returns truthy value if request fails, or if it's from a previously banned IP
      # so the request is blocked
      Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 0, findtime: 10.minutes, bantime: 1.hour) do
        # The count for the IP is incremented if the return value is truthy
        req.path.include?("/etc/passwd") ||
          req.path.include?("/wp-admin/") ||
          req.path.include?("/wp-login/") ||
          req.path.include?("SELECT") ||
          req.path.include?("CONCAT") ||
          req.path.include?("UNION%20SELECT") ||
          req.path.include?("/.git/")
      end
    end
  end
end
