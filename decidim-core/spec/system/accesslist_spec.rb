# frozen_string_literal: true

require "spec_helper"
require "rack/attack"

describe "Access list", type: :system do
  let!(:organization) { create(:organization) }
  let!(:admin) { create(:admin) }

  before do
    switch_to_host(organization.host)
    login_as admin, scope: :admin
  end

  it "allows access to participants side" do
    visit decidim.root_path

    expect(page).to have_content(organization.name)
  end

  it "allows access to system side page" do
    visit decidim_system.root_path

    expect(page).to have_content("Dashboard")
  end

  context "when an access list has been specified" do
    let(:headers) { { "REMOTE_ADDR" => "127.0.0.1", "decidim.current_organization" => organization } }

    before do
      allow(Decidim.config).to receive(:system_accesslist_ips).and_return(["127.0.0.1"])
    end

    it "allows access to participants side" do
      visit decidim.root_path

      expect(page).to have_content(organization.name)
    end

    it "allows access to system side page" do
      visit decidim_system.root_path

      expect(page).to have_content("Dashboard")
      expect(page).not_to have_content("Forbidden")
    end

    context "when request ip doesn't match access list" do
      let(:headers) { { "REMOTE_ADDR" => "128.0.0.1", "decidim.current_organization" => organization } }

      it "denies access to system side page" do
        get decidim_system.root_path, params: {}, headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
