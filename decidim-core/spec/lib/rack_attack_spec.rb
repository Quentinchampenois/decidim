# frozen_string_literal: true

require "spec_helper"

describe "Rack Attack", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  let(:organization) { create(:organization) }

  describe "Throttling" do
    let(:headers) { { "REMOTE_ADDR" => "1.2.3.4", "decidim.current_organization" => organization } }

    it "accepts 100 requests and then block requests" do
      100.times do |_|
        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:ok)
      end

      get decidim.root_path, params: {}, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Retry later")

      travel_to(1.minute.from_now) do
        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Throttling user sign in" do
    let(:headers) { { "REMOTE_ADDR" => "2.3.4.5", "decidim.current_organization" => organization } }
    let(:params) { { "user" => { "email" => "user@example.org" } } }

    it "accepts 5 requests and then block requests" do
      5.times do |_|
        post "/users/sign_in", params: params, headers: headers
        expect(response).to have_http_status(:ok)
      end

      post "/users/sign_in", params: params, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Retry later")

      travel_to(1.minute.from_now) do
        post "/users/sign_in", params: params, headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Throttling user password recovery" do
    let(:headers) { { "REMOTE_ADDR" => "3.4.5.6", "decidim.current_organization" => organization } }
    let(:params) { { "user" => { "email" => "user@example.org" } } }

    it "accepts 5 requests and then block requests" do
      5.times do |_|
        post "/users/password", params: params, headers: headers
        expect(response).to have_http_status(:found)
      end

      post "/users/password", params: params, headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Retry later")

      travel_to(1.minute.from_now) do
        post "/users/password", params: params, headers: headers
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe "Fail2Ban" do
    let(:headers) { { "REMOTE_ADDR" => "3.4.5.6", "decidim.current_organization" => organization } }

    %w(/etc/passwd /wp-admin/index.php /wp-login/index.php SELECT CONCAT /.git/config).each do |path|
      it "blocks user for specific request : '#{path}'" do
        get "#{decidim.root_path}#{path}", params: {}, headers: headers
        expect(response).to have_http_status(:forbidden)

        get decidim.root_path, params: {}, headers: headers
        expect(response).to have_http_status(:forbidden)

        travel_to(61.minutes.from_now) do
          get decidim.root_path, params: {}, headers: headers
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
