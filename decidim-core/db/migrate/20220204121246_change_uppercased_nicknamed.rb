# frozen_string_literal: true

class ChangeUppercasedNicknamed < ActiveRecord::Migration[6.0]
  def up
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

        # Update user's nickname as lowercased and ending with '-1', '-2' incremented according to the number of similar user nicknames.
        if similar_user.update!(nickname: "#{similar_user.nickname.downcase}-#{index + 1}")
          send_notification_to(similar_user, "#{similar_user.nickname.downcase}-#{index + 1}")
          has_changed.append(similar_user)
        end
      end

      # Update the current user nickname to lowercase
      if user.update!(nickname: user.nickname.downcase)
        send_notification_to(user, user.nickname.downcase)
        has_changed.append(user)
      end
    end
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
end
