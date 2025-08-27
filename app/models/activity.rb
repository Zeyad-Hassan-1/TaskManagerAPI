class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :actor, polymorphic: true
  belongs_to :notifiable, polymorphic: true
end
