class Book < ApplicationRecord
  belongs_to :author
  belongs_to :publisher
  has_one :image, as: :imageable

  serialize :openstruct, OpenStructSerializer
  serialize :hash, Hash
  serialize :array, Array

  scope :hard_cover, -> { where(hard_cover: true) }
  scope :soft_cover, -> { where(hard_cover: false) }
  scope :expensive, -> { where('amount > ?', 250) }
  scope :more_expensive_than, ->(price) { where('amount > ?', price) }
  scope :since, ->(ago) { where("created_at > ?", ago) }
end
