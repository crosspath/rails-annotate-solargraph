module OpenStructSerializer
  class << self
    def object_class
      ::OpenStruct
    end

    def load(_); end
    def dump(_); end
  end
end
