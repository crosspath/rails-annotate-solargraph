class Essay < ApplicationRecord
  belongs_to :author
  has_one :image, through: :author

  scope :since, ->(ago) { where("created_at > ?", ago) }
end
