class RefreshToken < ApplicationRecord
  belongs_to :user
  scope :active, -> { where("expires_at > ? AND revoked_at IS NULL", Time.current) }
  validates :token_digest, presence: true, uniqueness: true

  def expired?
    Time.current >= expires_at
  end
end
