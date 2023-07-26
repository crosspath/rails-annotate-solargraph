class Author < AbstractRecord
  has_many :books
  has_many :essays
  has_one :image, as: :imageable

  scope :since, ->(ago) { where("created_at > ?", ago) }
end
