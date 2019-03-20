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
            update_answer unless form.answer.blank?
            create_attachment if process_attachments?
          end

          broadcast(:ok, question)
        end

        private

        attr_reader :form, :question, :attachment

        def update_question
          return update_without_versioning unless versioned_attributes_changed?

          update_with_versioning
        end

        def update_answer
          PaperTrail.request(enabled: false) do
            question.update!(
              answer: form.answer,
              answered_at: Time.current
            )
          end
        end

        def update_with_versioning
          Decidim.traceability.update!(
            question,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            recipient: form.recipient,
            state: form.state
          )
        end

        def update_without_versioning
          PaperTrail.request(enabled: false) do
            question.update!(
              recipient: form.recipient,
              state: form.state
            )
          end
        end

        # Return true if diff between form and model include versioned attributes
        def versioned_attributes_changed?
          diff = Decidim::Questions::Question::VERSIONED_ATTRIBUTES.map do |attr|
            true if form.send(attr) != question.send(attr)
          end

          diff.include? true
        end
      end
    end
  end
end
