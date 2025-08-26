class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  has_one_attached :file

  validates :link, presence: true, if: -> { file.blank? }
  validates :file, presence: true, if: -> { link.blank? }
end
