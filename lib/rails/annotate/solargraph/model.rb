# frozen_string_literal: true

module Rails
  module Annotate
    module Solargraph
      class Model
        using TerminalColors::Refinement

        # @return [String]
        ANNOTATION_START = "\n# %%<RailsAnnotateSolargraph:Start>%%"
        # @return [String]
        ANNOTATION_END = "%%<RailsAnnotateSolargraph:End>%%\n\n"
        # @return [Regexp]
        ANNOTATION_REGEXP = /#{ANNOTATION_START}.*#{ANNOTATION_END}/m.freeze
        # @return [Regexp]
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
          old_content, file_content = remove_annotation write: false

          if CONFIG.annotation_position == :top
            magic_comments = file_content.scan(MAGIC_COMMENT_REGEXP).flatten.compact.join
            file_content.sub!(MAGIC_COMMENT_REGEXP, '')

            new_file_content = magic_comments + annotation + file_content
          else
            new_file_content = file_content + annotation
          end

          return new_file_content unless write
          # debugger
          return new_file_content if old_content == new_file_content

          write_file @file_name, new_file_content
          new_file_content
        end

        # @param :write [Boolean]
        # @return [Array<String>] Old file content followed by new content.
        def remove_annotation(write: true)
          file_content = ::File.read(@file_name)
          new_file_content = file_content.sub(ANNOTATION_REGEXP, '')
          result = [file_content, new_file_content]
          return result unless write
          return result if file_content == new_file_content

          write_file @file_name, new_file_content
          result
        end

        # @return [String]
        def annotation
          doc_string = ::String.new
          doc_string << <<~DOC
            #{ANNOTATION_START}
            # @!parse
            #   class #{@klass} < #{@klass.superclass}
          DOC

          @klass.reflections.each do |attr_name, reflection|
            next document_polymorphic_relation(doc_string, attr_name, reflection) if reflection.polymorphic?

            document_relation(doc_string, attr_name, reflection)
          end

          @klass.attribute_types.each do |name, attr_type|
            doc_string << <<~DOC
              #     # Database column `#{@klass.table_name}.#{name}`, type: `#{attr_type.type}`.
              #     # @param val [#{yard_type attr_type}, nil]
              #     def #{name}=(val); end
              #     # Database column `#{@klass.table_name}.#{name}`, type: `#{attr_type.type}`.
              #     # @return [#{yard_type attr_type}, nil]
              #     def #{name}; end
            DOC
          end

          doc_string << <<~DOC.chomp
            #   end
            # #{ANNOTATION_END}
          DOC
        end

        private

        # @param file_name [String]
        # @return [String]
        def relative_file_name(file_name)
          file_name.delete_prefix("#{::Rails.root}/")
        end

        # @param file_name [String]
        # @param content [String]
        # @return [void]
        def write_file(file_name, content)
          ::File.write(file_name, content)
          puts "modify".rjust(12).with_styles(:bold, :green) + "  #{relative_file_name(file_name)}"
        end

        # @return [String]
        def klass_relation_name
          @klass.table_name[..-2]
        end

        # @param doc_string [String]
        # @param attr_name [String]
        # @param reflection [ActiveRecord::Reflection::AbstractReflection]
        # @return [void]
        def document_relation(doc_string, attr_name, reflection)
          db_description = \
            case reflection
            when ::ActiveRecord::Reflection::BelongsToReflection
              type_docstring = reflection.klass
              "`belongs_to` relation with `#{reflection.klass}`. Database column `#{@klass.table_name}.#{reflection.foreign_key}`."
            when ::ActiveRecord::Reflection::HasOneReflection
              type_docstring = reflection.klass
              "`has_one` relation with `#{reflection.klass}`. Database column `#{reflection.klass.table_name}.#{reflection.foreign_key}`."
            when ::ActiveRecord::Reflection::HasManyReflection
              type_docstring = "Array<#{reflection.klass}>"
              "`has_many` relation with `#{reflection.klass}`. Database column `#{reflection.klass.table_name}.#{reflection.foreign_key}`."
            end

          doc_string << <<~DOC
            #     # #{db_description}
            #     # @param val [#{type_docstring}, nil]
            #     def #{attr_name}=(val); end
            #     # #{db_description}
            #     # @return [#{type_docstring}, nil]
            #     def #{attr_name}; end
          DOC
        end

        # @param doc_string [String]
        # @param attr_name [String]
        # @param reflection [ActiveRecord::Reflection::AbstractReflection]
        # @return [void]
        def document_polymorphic_relation(doc_string, attr_name, reflection)
          classes = Solargraph.model_classes.select do |model_class|
            model_class.reflections[klass_relation_name]&.options&.[](:as)&.to_sym == attr_name.to_sym
          end

          classes_string = classes.join(', ')
          doc_string << <<~DOC
            #     # Polymorphic relation. Database columns `#{@klass.table_name}.#{attr_name}_id` and `#{@klass.table_name}.#{attr_name}_type`.
            #     # @param val [#{classes_string}, nil]
            #     def #{attr_name}=(val); end
            #     # Polymorphic relation. Database columns `#{@klass.table_name}.#{attr_name}_id` and `#{@klass.table_name}.#{attr_name}_type`.
            #     # @return [#{classes_string}, nil]
            #     def #{attr_name}; end
          DOC
        end

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
