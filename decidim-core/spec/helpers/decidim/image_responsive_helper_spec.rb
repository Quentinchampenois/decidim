# frozen_string_literal: true

require "spec_helper"

module Decidim
  include CarrierWave::Test::Matchers
  describe ImageResponsiveHelper, type: :helper do

    # Si l'image n'existe pas
    # Si l'image n'est pas une image

    describe "#image_responsive" do
      # let!(:banner_image) { Decidim::Dev.test_file("city2.jpeg", "image/jpeg") }
      # let!(:participatory_process) { create(:participatory_process, banner_image: banner_image) }
      let(:participatory_process) { create(:participatory_process) }

      # OK
      it "includes picture html tag " do
        expect(helper.image_responsive(participatory_process.banner_image)).to include("<picture>")
        expect(helper.image_responsive(participatory_process.banner_image)).to include("<source media=\"(max-width: 768px)\" srcset=\"/uploads/decidim/participatory_process/banner_image/#{participatory_process.id}/xs_city2.jpeg\"></source>")
        expect(helper.image_responsive(participatory_process.banner_image)).to include("<source media=\"(max-width: 992px)\" srcset=\"/uploads/decidim/participatory_process/banner_image/#{participatory_process.id}/md_city2.jpeg\"></source>")
      end

      # OK
      it "displays a fallback img tag" do
        expect(helper.image_responsive(participatory_process.banner_image)).to include("<img src=\"/uploads/decidim/participatory_process/banner_image/#{participatory_process.id}/city2.jpeg\" />")
      end

      # OK
      context "when there is a missing version" do
        before do
          BannerImageUploader.versions.delete(:xs)
        end

        it "doesn't display the concerned version" do
          expect(helper.image_responsive(participatory_process.banner_image)).to include("<picture>")
          expect(helper.image_responsive(participatory_process.banner_image)).to include("<source media=\"(max-width: 992px)\" srcset=\"/uploads/decidim/participatory_process/banner_image/#{participatory_process.id}/md_city2.jpeg\"></source>")
          expect(helper.image_responsive(participatory_process.banner_image)).not_to include("<source media=\"(max-width: 768px)\" srcset=\"/uploads/decidim/participatory_process/banner_image/#{participatory_process.id}/xs_city2.jpeg\"></source>")
        end
      end

    end
  end
end
