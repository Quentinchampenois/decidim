# frozen_string_literal: true

module Decidim
  # This class deals with uploading banner images to ParticipatoryProcesses.
  class BannerImageUploader < ImageUploader
    process resize_to_limit: [1920, 600]

    version :xs do
      process resize_to_limit: [1080, 340]
    end

    version :md do
      process resize_to_limit: [1440, 450]
    end
  end
end
