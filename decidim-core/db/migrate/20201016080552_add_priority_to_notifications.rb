class AddPriorityToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :priority, :integer, null: false, default: 0
  end
end
