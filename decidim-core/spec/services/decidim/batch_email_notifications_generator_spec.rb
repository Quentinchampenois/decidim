# frozen_string_literal: true

require "spec_helper"

describe Decidim::BatchEmailNotificationsGenerator do
  include ActionView::Helpers::DateHelper
  subject { described_class.new }

  let!(:user) { create(:user) }
  let!(:notifications) { create_list(:notification, 12, :now_priority, user: user) }
  let(:serialized_event) do
    {
      resource: notifications.first.resource,
      event_class: notifications.first.event_class,
      event_name: notifications.first.event_name,
      user: notifications.first.user,
      extra: notifications.first.extra,
      priority: notifications.first.priority,
      user_role: notifications.first.user_role,
      created_at: time_ago_in_words(notifications.first.created_at).capitalize
    }
  end

  describe "#generate" do
    let(:mailer) { double(deliver_later: true) }

    it "doesn't enqueues the job" do
      expect(Decidim::BatchNotificationsMailer)
        .not_to receive(:event_received)
        .with(subject.send(:serialized_events, subject.send(:events_for, user)), user)

      expect(mailer).not_to receive(:deliver_later)

      subject.generate
    end

    it "doesn't marks the notifications has sent" do
      subject.generate

      expect(Decidim::Notification.where(decidim_user_id: user.id).where.not(sent_at: nil).count).to eq(0)
    end

    context "when notifications are marked as batch priority" do
      let!(:notifications) { create_list(:notification, 12, user: user) }

      it "enqueues the job" do
        expect(Decidim::BatchNotificationsMailer)
          .to receive(:event_received)
          .with(subject.send(:serialized_events, subject.send(:events_for, user)), user)
          .and_return(mailer)
          .once

        expect(mailer).to receive(:deliver_later)

        subject.generate
      end

      it "marks the notifications has sent" do
        subject.generate
        expect(Decidim::Notification.where(decidim_user_id: user.id).where.not(sent_at: nil).count).to eq(5)
      end

      context "when user doesn't want to receive email notification" do
        let!(:user) { create(:user, email_on_notification: false) }

        it "doesn't schedule a job for each recipient" do
          expect(Decidim::BatchNotificationsMailer)
            .not_to receive(:event_received)

          subject.generate
        end
      end

      context "when user deletes her account before notification has been sent" do
        before do
          user.destroy!
        end

        it "doesn't enqueues the job" do
          expect(Decidim::BatchNotificationsMailer)
            .not_to receive(:event_received)
            .with(subject.send(:serialized_events, subject.send(:events_for, user)), user)

          expect(mailer).not_to receive(:deliver_later)

          expect do
            perform_enqueued_jobs { subject.generate }
          end.not_to change(emails, :count)
        end
      end
    end

    context "when there is no events" do
      let(:notifications) { nil }

      it "doesn't schedule a job for each recipient" do
        expect(Decidim::BatchNotificationsMailer)
          .not_to receive(:event_received)

        subject.generate
      end
    end
  end

  describe "#events" do
    context "when notifications are marked as batch priority" do
      let!(:notifications) { create_list(:notification, 14, user: user) }

      it "returns notifications" do
        expect(subject.send(:events)).to match_array(notifications)
        expect(subject.send(:events).length).to eq(14)
      end

      context "with batch_email_notifications_expired" do
        before do
          notifications.last.update!(created_at: 2.weeks.ago)
        end

        it "does not fetch the expired notifications" do
          expect(subject.send(:events)).not_to include(notifications.last)
          expect(subject.send(:events).length).to eq(13)
        end
      end

      context "when notifications has already been sent" do
        let!(:notifications) { create_list(:notification, 14, user: user) }

        before do
          notifications.first.update!(sent_at: 12.hours.ago)
        end

        it "doesn't includes it" do
          expect(subject.send(:events)).not_to include(notifications.first)
          expect(subject.send(:events).length).to eq(13)
        end
      end
    end
  end

  describe "#events_for" do
    context "when notifications are marked as batch priority" do
      let!(:notifications) { create_list(:notification, 12, user: user) }
      let(:another_user) { create(:user) }
      let(:notification) { create(:notification, user: another_user) }

      it "returns notifications for user" do
        expect(subject.send(:events_for, user)).not_to include(notification)
        expect(subject.send(:events_for, user)).to match_array(notifications.reverse.first(5))
        expect(subject.send(:events_for, user).length).to eq(5)
      end
    end
  end

  describe "#users" do
    context "when notifications are marked as batch priority" do
      let!(:notifications) { create_list(:notification, 12, user: user) }

      it "returns users" do
        expect(subject.send(:users)).to eq([user])
      end
    end
  end

  describe "#serialized_events" do
    it "returns serialized events" do
      expect(subject.send(:serialized_events, [notifications.first]))
        .to eq([serialized_event])
    end
  end

  describe "#mark_as_sent" do
    it "updates notifications" do
      subject.send(:mark_as_sent, subject.send(:events))
      expect(notifications.map(&:sent_at).any?).to eq(false)
    end
  end
end
