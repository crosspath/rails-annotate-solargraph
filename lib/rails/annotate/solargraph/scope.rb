# frozen_string_literal: true

module Rails
  module Annotate
    module Solargraph
      # Represents a scope on an ActiveRecord Model.
      class Scope
        # @param name [Symbol]
        attr_reader :name
        # @param model_class [Class]
        attr_reader :model_class
        # @param proc_parameters [Array<Symbol>]
        attr_reader :proc_parameters
        # @param definition [String]
        attr_reader :definition

        # @param name [Symbol]
        # @param model_class [Class]
        # @param proc_parameters [Array<Symbol>]
        # @param definition [String]
        def initialize(name:, model_class:, proc_parameters:, definition:)
          @name = name
          @model_class = model_class
          @proc_parameters = proc_parameters
          @definition = definition
          freeze
        end

        # @return [String]
        def documentation
          <<~DOC
            #     # Scope `#{@name.inspect}`.
            #     #
            #{documented_definition}
            #     #
            #     # @return [Array<#{@model_class}>, nil]
            #     #{signature}
          DOC
        end

        private

        # @return [String]
        def signature
          args = @proc_parameters.join(', ')

          "def self.#{@name}(#{args}); end"
        end

        # @return [String]
        def documented_definition
          result = ::String.new
          @definition.each_line do |line|
            result << "#     #     #{line}"
          end

          result.chomp
        end
      end
    end
  end
end
