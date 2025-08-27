require "digest"

class User < ApplicationRecord
    has_secure_password
    has_many :refresh_tokens, dependent: :destroy
    has_many :team_memberships, dependent: :destroy
    has_many :teams, through: :team_memberships
    has_many :project_memberships, dependent: :destroy
    has_many :projects, through: :project_memberships
    has_many :task_memberships, dependent: :destroy
    has_many :tasks, through: :task_memberships
    has_many :comments, dependent: :destroy
    has_many :attachments, dependent: :destroy
    has_many :sent_invitations, class_name: "Invitation", foreign_key: "inviter_id", dependent: :destroy
    has_many :received_invitations, class_name: "Invitation", foreign_key: "invitee_id", dependent: :destroy
    has_many :activities, dependent: :destroy
    validates :username, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 6 }, on: :create
    validates :password, length: { minimum: 6 }, allow_blank: false, if: :password_digest_changed?

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
        reset_token
    end

    def password_reset_expired?
        reset_sent_at < 1.hour.ago
    end

    private

    def password_required?
        password.present? || password_confirmation.present?
    end
end
