class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  belongs_to :user

  has_one_attached :file

  validates :link, presence: true, if: -> { file.blank? }
  validates :file, presence: true, if: -> { link.blank? }
end
