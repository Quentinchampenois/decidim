# frozen_string_literal: true

module Decidim
  module Initiatives
    # This custom Form builder add the fields needed to deal with
    # Initiative types.
    class InitiativesFilterFormBuilder < Decidim::FilterFormBuilder
      # Public: Generates a select field with the initiative types.
      #
      # name       - The name of the field (usually type_id)
      # collection - A collection of initiative types.
      # options    - An optional Hash with options:
      # - prompt   - An optional String with the text to display as prompt.
      #
      # Returns a String.
      def initiative_types_select(name, collection, options = {})
        selected = object.send(name)

        if selected.present? && selected != "all"
          selected = selected.values if selected.is_a?(Hash)
          selected = [selected] unless selected.is_a?(Array)
        end

        types = collection.all.map do |type|
          [type.title[I18n.locale.to_s], type.id]
        end

        prompt = options.delete(:prompt)
        remote_path = options.delete(:remote_path) || false
        multiple = options.delete(:multiple) || false
        html_options = {
          multiple: multiple,
          class: "select2",
          "data-remote-path" => remote_path,
          "data-placeholder" => prompt
        }

        select(name, @template.options_for_select(types, selected: selected), options, html_options)
      end
    end
  end
end
