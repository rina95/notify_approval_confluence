class NotificationJob < ApplicationJob
  queue_as :default

  def perform(data)
    ActionCable.server.broadcast "NotificationsChannel", { data: data }
  end
end