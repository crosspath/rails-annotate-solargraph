class Book < ApplicationRecord
  belongs_to :author
  belongs_to :publisher
  has_one :image, as: :imageable

  serialize :openstruct, OpenStructSerializer
  serialize :hash, Hash
  serialize :array, Array
end
