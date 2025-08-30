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
    has_one_attached :profile_picture
    validates :username, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 8 }, format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+\z/,
      message: "must contain at least one lowercase letter, one uppercase letter, one digit, and one special character (@$!%*?&)"
    }, on: :create
    validates :password, length: { minimum: 8 }, format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+\z/,
      message: "must contain at least one lowercase letter, one uppercase letter, one digit, and one special character (@$!%*?&)"
    }, allow_blank: false, if: :password_digest_changed?

    def profile_picture_url
        if profile_picture.attached?
            Rails.application.routes.url_helpers.rails_blob_url(profile_picture, only_path: true)
        end
    end

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
