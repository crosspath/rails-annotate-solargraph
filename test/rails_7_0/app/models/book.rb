class Book < ApplicationRecord
  serialize :openstruct, OpenStructSerializer
  serialize :hash, Hash
  serialize :array, Array
end
