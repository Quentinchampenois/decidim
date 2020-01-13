# frozen_string_literal: true

module Decidim
  module Initiatives
    class DataPortabilityInitiativesVoteSerializer < Decidim::Exporters::Serializer
      def serialize
        {
          id: resource.id,
          code: resource.code,
          author: {
            name: resource.author.name,
            email: resource.author.email
          },
          initiative: {
            title: resource.initiative.title,
            description: resource.initiative.description,
            type: {
              id: resource.initiative.type.try(:id),
              name: resource.initiative.type.try(:title) || empty_translatable
            },
            scope: {
              id: resource.initiative.scope.try(:id),
              name: resource.initiative.scope.try(:name) || empty_translatable
            },
            start_date: resource.initiative.signature_start_date,
            end_date: resource.initiative.signature_end_date,
            state: resource.initiative.state,
            answer: resource.initiative.answer
          }
        }
      end
    end
  end
end
