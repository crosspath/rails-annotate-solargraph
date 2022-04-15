# frozen_string_literal: true

require 'set'

module Rails
  module Annotate
    module Solargraph
      class Configuration
        # @return [Symbol]
        attr_reader :annotation_position

        ANNOTATION_POSITIONS = ::Set[:bottom, :top].freeze

        def initialize
          @annotation_position = :bottom
        end

        # @param val [Symbol]
        def annotation_position=(val)
          raise Error, "`annotation_position` is incorrect! Got `#{val.inspect}`, expected a member of `#{ANNOTATION_POSITIONS.inspect}`" \
           unless ANNOTATION_POSITIONS.include?(val)

          @annotation_position = val
        end
      end
    end
  end
end
