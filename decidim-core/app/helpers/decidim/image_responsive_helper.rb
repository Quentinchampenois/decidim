# frozen_string_literal: true

module Decidim
  # A Helper to render image according to the device screen
  module ImageResponsiveHelper
    def image_responsive(image, options = {})
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture
      # https://gist.github.com/armandfardeau/0730c917e4a2c82871b85d690b1b169f
      #
      # WARNING: Not supported on IE : https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture#Usage_notes

      content_tag(:picture) do
        concat content_tag(:source, nil, media: "(max-width: 768px)", srcset: image.url(:xs)) if image.version_exists? :xs
        concat content_tag(:source, nil, media: "(max-width: 992px)", srcset: image.url(:md)) if image.version_exists? :md
        concat image_tag(image.url, options)
      end
    end
  end
end
