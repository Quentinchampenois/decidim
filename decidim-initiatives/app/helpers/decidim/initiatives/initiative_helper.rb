# frozen_string_literal: true

module Decidim
  module Initiatives
    # Helper method related to initiative object and its internal state.
    module InitiativeHelper
      include Decidim::SanitizeHelper

      # Public: The css class applied based on the initiative state to
      #         the initiative badge.
      #
      # initiative - Decidim::Initiative
      #
      # Returns a String.
      def state_badge_css_class(initiative)
        return "success" if initiative.accepted?

        "warning"
      end

      # Public: The state of an initiative in a way a human can understand.
      #
      # initiative - Decidim::Initiative.
      #
      # Returns a String.
      def humanize_state(initiative)
        I18n.t(initiative.accepted? ? "accepted" : "expired",
               scope: "decidim.initiatives.states",
               default: :expired)
      end

      # Public: The state of an initiative in a way a human can understand.
      #
      # initiative - Decidim::Initiative.
      #
      # Returns a String.
      def humanize_initiative_state(initiative)
        I18n.t(initiative.state , scope: "decidim.initiatives.state", default: :created)
      end

      # Public: The state of an initiative from an administration perspective in
      # a way that a human can understand.
      #
      # state - String
      #
      # Returns a String
      def humanize_admin_state(state)
        I18n.t(state, scope: "decidim.initiatives.admin_states", default: :created)
      end

      def popularity_tag(initiative)
        content_tag(:div, class: "extra__popularity popularity #{popularity_class(initiative)}".strip) do
          5.times do
            concat(content_tag(:span, class: "popularity__item") {})
          end

          concat(content_tag(:span, class: "popularity__desc") do
            I18n.t("decidim.initiatives.initiatives.vote_cabin.supports_required",
                   total_supports: initiative.scoped_type.supports_required)
          end)
        end
      end

      def popularity_class(initiative)
        return "popularity--level1" if popularity_level1?(initiative)
        return "popularity--level2" if popularity_level2?(initiative)
        return "popularity--level3" if popularity_level3?(initiative)
        return "popularity--level4" if popularity_level4?(initiative)
        return "popularity--level5" if popularity_level5?(initiative)

        ""
      end

      def popularity_level1?(initiative)
        initiative.percentage.positive? && initiative.percentage < 40
      end

      def popularity_level2?(initiative)
        initiative.percentage >= 40 && initiative.percentage < 60
      end

      def popularity_level3?(initiative)
        initiative.percentage >= 60 && initiative.percentage < 80
      end

      def popularity_level4?(initiative)
        initiative.percentage >= 80 && initiative.percentage < 100
      end

      def popularity_level5?(initiative)
        initiative.percentage >= 100
      end

      def authorized_vote_modal_button(initiative, html_options, &block)
        return if current_user && action_authorized_to("vote", resource: initiative, permissions_holder: initiative.type).ok?

        tag = "button"
        html_options ||= {}
        action = initiative_initiative_signatures_path(initiative_slug: initiative.slug)

        if !current_user
          html_options["data-open"] = "loginModal"
          html_options["data-redirect-url"] = action
          request.env[:available_authorizations] = permissions_for(:vote, initiative.type)
        else
          html_options["data-open"] = "authorizationModal"
          html_options["data-open-url"] = authorization_sign_modal_initiative_path(initiative, redirect: action)
        end

        html_options["onclick"] = "event.preventDefault();"

        send("#{tag}_to", "", html_options, &block)
      end

      def authorized_creation_modal_button_to(action, html_options, &block)
        html_options ||= {}

        if !current_user
          html_options["data-open"] = "loginModal"
          html_options["data-redirect-url"] = action
          request.env[:available_authorizations] = merged_permissions_for(:create)
        else
          html_options["data-open"] = "authorizationModal"
          html_options["data-open-url"] = authorization_creation_modal_path(redirect: action)
        end

        html_options["onclick"] = "event.preventDefault();"

        send("button_to", "", html_options, &block)
      end

      def authorized_creation_modal_for_type_button_to(type, action, html_options, &block)
        html_options ||= {}

        if !current_user
          html_options["data-open"] = "loginModal"
          binder = action.include?("?") ? "&" : "?"
          html_options["data-redirect-url"] = "#{action}#{binder}type_id=#{type.id}"
          request.env[:available_authorizations] = merged_permissions_for(:create)
        else
          html_options["data-open"] = "authorizationModal"
          html_options["data-open-url"] = authorization_creation_modal_initiative_type_path(type.id, redirect: action)
        end

        html_options["onclick"] = "event.preventDefault();"

        send("button_to", "", html_options, &block)
      end

      def any_initiative_types_authorized?
        return unless current_user
        Decidim::Initiatives::InitiativeTypes.for(current_user.organization).inject do |result, type|
          result && ActionAuthorizer.new(current_user, :create, type, type).authorize.ok?
        end
      end

      def permissions_for(action, type)
        return [] unless type.permissions
        type.permissions.dig(action.to_s,"authorization_handlers").keys
      end

      def merged_permissions_for(action)
        Decidim::Initiatives::InitiativeTypes.for(current_organization).map do |type|
          permissions_for(action,type)
        end.inject do |result, list|
          result + list
        end.uniq
      end
    end
  end
end
