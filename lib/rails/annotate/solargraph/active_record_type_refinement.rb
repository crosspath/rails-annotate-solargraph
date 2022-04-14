# frozen_string_literal: true

module Rails
  module Annotate
    module Solargraph
      module ActiveRecordTypeRefinement
        refine ::ActiveModel::Type::Value do
          # @return [String]
          def yard_type
            ::Rails::Annotate::Solargraph::Model.active_record_type_to_yard(type)
          end
        end

        refine ::ActiveModel::Type::Serialized do
          # @return [String]
          def yard_type
            return coder.object_class.to_s if coder.respond_to?(:object_class)
            return 'Object' if coder.is_a?(::ActiveRecord::Coders::JSON)

            ::Rails::Annotate::Solargraph::Model.active_record_type_to_yard(type)
          end
        end
      end
    end
  end
end
