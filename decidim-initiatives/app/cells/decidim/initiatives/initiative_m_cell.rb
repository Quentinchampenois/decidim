# frozen_string_literal: true

module Decidim
  module Initiatives
    # This cell renders the Medium (:m) initiative card
    # for an given instance of an Initiative
    class InitiativeMCell < Decidim::CardMCell
      include InitiativeHelper
      include Decidim::Initiatives::Engine.routes.url_helpers

      property :state

      private

      def translatable?
        true
      end

      def title
        decidim_html_escape(translated_attribute(model.title))
      end

      def hashtag
        decidim_html_escape(model.hashtag)
      end

      def has_state?
        true
      end

      def state_classes
        case state
        when "accepted", "published", "debatted"
          ["success"]
        when "rejected", "discarded", "classified"
          ["alert"]
        when "validating", "examinated"
          ["warning"]
        else
          ["muted"]
        end
      end

      def resource_path
        initiative_path(model)
      end

      def resource_icon
        icon "initiatives", class: "icon--big"
      end

      def authors
        [present(model).author] +
          model.committee_members.approved.non_deleted.excluding_author.map { |member| present(member.user) }
      end

      def badge_name
        humanize_initiative_state model
      end

      def comments_count
        return 0 unless model.type.comments_enabled
        return model.comments.not_hidden.count if model.comments.respond_to? :not_hidden

        model.comments.count
      end

      def comments_count_status
        return unless model.type.comments_enabled
        return render_comments_count unless has_link_to_resource?

        link_to resource_path do
          render_comments_count
        end
      end
    end
  end
end
