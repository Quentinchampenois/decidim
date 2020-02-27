# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"

module Decidim
  module Assemblies
    describe AssembliesTypeType, type: :graphql do
      include_context "with a graphql type"

      let(:model) { create(:assemblies_type) }

      describe "id" do
        let(:query) { "{ id }" }

        it "returns the id field" do
          expect(response["id"]).to eq(model.id.to_s)
        end
      end

      describe "title" do
        let(:query) { '{ title { translation(locale:"en") }}' }

        it "returns the field title" do
          expect(response["title"]["translation"]).to eq(model.title["en"])
        end
      end

      describe "createdAt" do
        let(:query) { "{ createdAt }" }

        it "returns when the assembly member was created" do
          expect(response["createdAt"]).to eq(model.created_at.to_time.iso8601)
        end
      end

      describe "updatedAt" do
        let(:query) { "{ updatedAt }" }

        it "returns when the assembly member was updated" do
          expect(response["updatedAt"]).to eq(model.updated_at.to_time.iso8601)
        end
      end
    end
  end
end
