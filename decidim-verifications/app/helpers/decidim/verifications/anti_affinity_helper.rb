# frozen_string_literal: true

module Decidim
  module Verifications
    # Helper method related to initiative object and its internal state.
    module AntiAffinityHelper
      include Decidim::SanitizeHelper

      def disabled_methods
        @disabled_methods ||= available_verification_workflows.select do |handler|
          authorization_anti_affinity.include?(handler.key)
        end
      end

      def authorization_anti_affinity
        @authorization_anti_affinity ||= active_authorization_methods.map do |handler|
          Decidim::Verifications.find_workflow_manifest(handler).anti_affinity
        end.flatten.compact
      end

      def active_authorization_methods
        Decidim::Verifications::Authorizations.new(organization: current_organization, user: current_user).pluck(:name)
      end

      # Public: Available authorization handlers in order to conditionally
      # show the menu element.
      def available_verification_workflows
        Verifications::Adapter.from_collection(
          current_organization.available_authorizations & Decidim.authorization_workflows.map(&:name)
        )
      end
    end
  end
end
