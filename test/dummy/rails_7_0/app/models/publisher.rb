class Publisher < ApplicationRecord
  has_many :books
  has_many :authors, through: :books

  scope :since, ->(ago) { where("created_at > ?", ago) }
end
