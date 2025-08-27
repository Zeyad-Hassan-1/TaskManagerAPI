module Notifiable
  extend ActiveSupport::Concern

  def create_notification(user, notifiable, action)
    Activity.create(
      user: user,
      actor: current_user,
      notifiable: notifiable,
      action: action
    )
  end
end
