class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  validates :link, presence: true
end
