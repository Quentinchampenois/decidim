# frozen_string_literal: true

require "spec_helper"
require "support/tasks"

describe "rake decidim:batch_email_notifications:send", type: :task do
  let(:task_name) { :"decidim:batch_email_notifications:send" }
  let(:argument_error_output) { /Rake aborted !/ }

  let!(:user) { create(:user) }
  let!(:notifications) { create_list(:notification, 2, user: user) }
  let!(:now_notifications) { create_list(:notification, 3, :now_priority, user: user) }

  context "when executing task" do
    it "raises an ArgumentError" do
      Rake::Task[task_name].reenable
      expect { Rake::Task[task_name].invoke }.to output(/ArgumentError : Rake aborted !/).to_stdout
    end

    context "when batch email notifications is enabled" do
      before do
        Decidim.config.batch_email_notifications_enabled = true
      end

      after do
        Decidim.config.batch_email_notifications_enabled = false
      end

      it "has to be executed without failures" do
        expect(Decidim::BatchEmailNotificationsGeneratorJob).to receive(:perform_later)
        Rake::Task[task_name].execute
      end

      it "send the batch notifications only" do
        expect(Decidim::Notification.where(sent_at:nil).count).to eq(5)
        Rake::Task[task_name].execute
        expect(Decidim::Notification.where.not(sent_at:nil).count).to eq(3)
      end

      it "enqueues mailers" do
        expect(Decidim::BatchEmailNotificationsGeneratorJob.queue_name).to eq "scheduled"
      end
    end
  end
end
