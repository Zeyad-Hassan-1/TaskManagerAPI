class Invitation < ApplicationRecord
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User"
  belongs_to :invitable, polymorphic: true

  validates :role, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted declined] }

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def declined?
    status == "declined"
  end
end
