# frozen_string_literal: true

namespace :decidim do
  namespace :batch_email_notifications do
    desc "Send email notifications in batch"
    task send: :environment do
      raise ArgumentError unless Decidim.config.batch_email_notifications_enabled

      puts "Running BatchEmailNotificationsGeneratorJob..."

      Decidim::BatchEmailNotificationsGeneratorJob.perform_later

      # Without sidekiq it kills the process and it is not sent : Use sleep 1.minute
      sleep 1.minute

      puts "Task succeeded !"
    rescue ArgumentError => e
      puts "#{e} : Rake aborted !"
      puts "Batch email notifications is disabled on this app"
      puts "Please set Decidim.config.batch_email_notifications_enabled to 'true' in initializers to use this command"
    end
  end
end
