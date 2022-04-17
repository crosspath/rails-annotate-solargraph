class Essay < ApplicationRecord
  belongs_to :author
  has_one :image, through: :author
end
