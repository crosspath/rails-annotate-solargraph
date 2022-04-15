# frozen_string_literal: true

module Rails
  module Annotate
    module Solargraph
      class Model
        ANNOTATION_START = "\n# %%<RailsAnnotateSolargraph:Start>%%"
        ANNOTATION_END = "%%<RailsAnnotateSolargraph:End>%%\n"
        ANNOTATION_REGEXP = /#{ANNOTATION_START}.*#{ANNOTATION_END}\n/m.freeze
        MAGIC_COMMENT_REGEXP = /(^#\s*encoding:.*(?:\n|r\n))|(^# coding:.*(?:\n|\r\n))|(^# -\*- coding:.*(?:\n|\r\n))|(^# -\*- encoding\s?:.*(?:\n|\r\n))|(^#\s*frozen_string_literal:.+(?:\n|\r\n))|(^# -\*- frozen_string_literal\s*:.+-\*-(?:\n|\r\n))/.freeze

        class << self
          # @param type [Symbol, String, nil]
          # @return [String]
          def active_record_type_to_yard(type)
            case type&.to_sym
            when :float
              ::Float.to_s
            when :integer
              ::Integer.to_s
            when :decimal
              ::BigDecimal.to_s
            when :datetime, :timestamp, :time
              ::Time.to_s
            when :json, :jsonb
              ::Hash.to_s
            when :date
              ::Date.to_s
            when :text, :string, :binary, :inet, :uuid
              ::String.to_s
            when :boolean
              'Boolean'
            else
              ::Object.to_s
            end
          end
        end

        # @return [String]
        attr_reader :file_name

        # @return [Class]
        attr_reader :klass

        # @param klass [Class]
        def initialize(klass)
          @klass = klass
          @file_name = ::File.join(::Rails.root, MODEL_DIR, "#{klass.to_s.underscore}.rb")
        end

        # @param :write [Boolean]
        # @return [String] New file content.
        def annotate(write: true)
          file_content = remove_annotation write: false

          if CONFIG.annotation_position == :top
            magic_comments = file_content.scan(MAGIC_COMMENT_REGEXP).flatten.compact.join
            file_content.sub!(MAGIC_COMMENT_REGEXP, '')

            new_file_content = magic_comments + annotation + file_content
          else
            new_file_content = file_content + annotation
          end

          return new_file_content unless write

          ::File.write @file_name, new_file_content
          new_file_content
        end

        # @param :write [Boolean]
        # @return [String] New file content.
        def remove_annotation(write: true)
          file_content = ::File.read(@file_name).sub(ANNOTATION_REGEXP, '')
          return file_content unless write

          ::File.write @file_name, file_content
          file_content
        end

        # @return [String]
        def annotation
          result = ::String.new
          result << <<~DOC
            #{ANNOTATION_START}
            # @!parse
            #   class #{@klass} < #{@klass.superclass}
          DOC

          @klass.attribute_types.each do |name, attr_type|
            result << <<~DOC
              #     # Database column `#{@klass.table_name}.#{name}`, type: `#{attr_type.type}`.
              #     # @param val [#{yard_type attr_type}, nil]
              #     def #{name}=(val); end
              #     # Database column `#{@klass.table_name}.#{name}`, type: `#{attr_type.type}`.
              #     # @return [#{yard_type attr_type}, nil]
              #     def #{name}; end
            DOC
          end

          result << <<~DOC
            #   end
            # #{ANNOTATION_END}
          DOC
        end

        private

        # @param attr_type [ActiveModel::Type::Value]
        # @return [String]
        def yard_type(attr_type)
          return attr_type.coder.object_class.to_s if attr_type.respond_to?(:coder) && attr_type.coder.respond_to?(:object_class)
          return 'Object' if attr_type.respond_to?(:coder) && attr_type.coder.is_a?(::ActiveRecord::Coders::JSON)

          self.class.active_record_type_to_yard(attr_type.type)
        end
      end
    end
  end
end
