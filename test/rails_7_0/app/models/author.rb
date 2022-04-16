class Author < ApplicationRecord
  has_many :books
  has_many :essays
  has_one :image, as: :imageable
end
