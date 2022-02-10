# frozen_string_literal: true
# This migration comes from decidim (originally 20220204121246)

class ChangeUppercasedNicknamedd < ActiveRecord::Migration[6.0]
  def up
    logger = Logger.new($stdout)
    logger.info("Updating users nickname...")

    # Store each users updated
    has_changed = []

    Decidim::User.find_each do |user|
      next if has_changed.include? user
      # Next if user's nickname already match the wanted lowercase format
      next if user.nickname.downcase == user.nickname

      # Fetch all users with a similar nickname (case insensitive)
      Decidim::User.where("nickname ILIKE ?", user.nickname.downcase).order(:created_at).each_with_index do |similar_user, index|
        next if has_changed.include? similar_user
        next if user == similar_user

        logger.info("User similar ID : #{similar_user.id}")
        # Update user's nickname as lowercased and ending with '-1', '-2' incremented according to the number of similar user nicknames.
        if similar_user.update!(nickname: "#{similar_user.nickname.downcase}-#{index + 1}")
          send_notification_to(similar_user, "#{similar_user.nickname.downcase}-#{index + 1}")
          has_changed.append(similar_user)
        end

        updated = begin
                    update_user_nickname(similar_user, "#{similar_user.nickname.downcase}-#{index + 1}")
                  rescue ActiveRecord::RecordInvalid => e
                    logger.warn("An error happened : #{e}")
                    update_user_nickname(similar_user, "#{similar_user.nickname.downcase}-#{rand(999)}")
                  end

        has_changed.append(updated) unless updated.blank?

      end
      logger.info("User ID: #{user.id}")
      logger.info("to #{user.nickname.downcase}")
      # Update the current user nickname to lowercase
      updated = begin
                  update_user_nickname(user, "#{user.nickname.downcase}")
                rescue ActiveRecord::RecordInvalid => e
                  logger.warn("An error happened : #{e}")
                  update_user_nickname(user, "#{user.nickname.downcase}-#{rand(999)}")
                end

      has_changed.append(updated) unless updated.blank?
    end

    logger.info("Process terminated, #{has_changed.count} users nickname have been updated.")
  end

  def send_notification_to(user, new_nickname)
    Decidim::EventsManager.publish({
                                     event: "decidim.events.nickname_event",
                                     event_class: Decidim::ChangeNicknameEvent,
                                     affected_users: [user],
                                     resource: user,
                                     extra: {
                                       old_nickname: user.nickname,
                                       new_nickname: new_nickname
                                     }
                                   })
  end

  def update_user_nickname(user, new_nickname)
    # Update user's nickname as lowercased and ending with '-1', '-2' incremented according to the number of similar user nicknames.
    if user.update!(nickname: new_nickname)
      send_notification_to(user, new_nickname)

      user
    end
  end
end

