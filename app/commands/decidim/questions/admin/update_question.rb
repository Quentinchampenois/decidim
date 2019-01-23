# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when a user updates a question.
      class UpdateQuestion < Rectify::Command
        include AttachmentMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # question - the question to update.
        def initialize(form, question)
          @form = form
          @question = question
          @attached_to = question
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the question.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            @question.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          transaction do
            update_question
            create_attachment if process_attachments?
          end

          broadcast(:ok, question)
        end

        private

        attr_reader :form, :question, :attachment

        def update_question
          return update_without_versioning if only_recipient_or_state_changed?

          update_with_versioning
        end

        def update_with_versioning
          Decidim.traceability.update!(
            question,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            scope: form.scope,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting,
            recipient: form.recipient,
            state: form.state
          )
        end

        def update_without_versioning
          PaperTrail.request(enabled: false) do
            @question.update!(
              recipient: form.recipient,
              state: form.state
            )
          end
        end

        def only_recipient_or_state_changed?
          # TODO: FIND A MORE ELEGANT WAY
          form.attributes[:title] == question.attributes["title"] &&
            form.attributes[:body] == question.attributes["body"] &&
            form.attributes[:category] == question.attributes["category"] &&
            (
            form.attributes[:state] != question.attributes["state"] ||
                form.attributes[:recipient] != question.attributes["recipient"]
          )
        end
      end
    end
  end
end
