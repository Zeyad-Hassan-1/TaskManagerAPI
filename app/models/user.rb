require "digest"

class User < ApplicationRecord
    has_secure_password
    has_many :refresh_tokens, dependent: :destroy
    validates :username, uniqueness: true

    # returns the RAW token (client uses this), stores only SHA256 digest
    def generate_refresh_token
        raw   = SecureRandom.hex(64)
        digest = Digest::SHA256.hexdigest(raw)
        refresh_tokens.create!(
        token_digest: digest,
        expires_at: 7.days.from_now
        )
        raw
    end

    # revoke all tokens for this user
    def revoke_all_refresh_tokens!
        refresh_tokens.update_all(revoked_at: Time.current)
    end

    def generate_password_reset_token!
        self.reset_token = SecureRandom.urlsafe_base64
        self.reset_sent_at = Time.now.utc
        save!(validate: false) # Skip validations for password reset
    end

    def password_reset_expired?
        reset_sent_at < 1.hour.ago
    end
end
