class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  scope :since, ->(ago) { where("created_at > ?", ago) }
  scope :between, ->(from, to) { where("created_at > ? AND created_at < ?", from, to) }
end
