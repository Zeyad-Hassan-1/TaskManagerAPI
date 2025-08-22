class RefreshToken < ApplicationRecord
  belongs_to :user
  scope :active, -> { where("expires_at > ?", Time.current) }
  validates :token_digest, presence: true, uniqueness: true

  def expired?
    Time.current >= expires_at
  end
end
