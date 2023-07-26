# frozen_string_literal: true

require 'set'

module Rails
  module Annotate
    module Solargraph
      class Configuration
        # @return [Symbol]
        attr_reader :annotation_position

        ANNOTATION_POSITIONS = ::Set[:bottom, :top, :schema_file].freeze

        def initialize
          @annotation_position = :schema_file
        end

        # @param val [Symbol]
        def annotation_position=(val)
          unless ANNOTATION_POSITIONS.include?(val)
            raise Error,
                  "`annotation_position` is incorrect! Got `#{val.inspect}`, " \
                  "expected a member of `#{ANNOTATION_POSITIONS.inspect}`"
          end

          @annotation_position = val
        end

        def schema_file?
          @annotation_position == :schema_file
        end
      end
    end
  end
end
