# frozen_string_literal: true

require 'fileutils'

module Rails
  module Annotate
    module Solargraph
      class Model
        using TerminalColors::Refinement

        # @return [Regexp]
        MAGIC_COMMENT_REGEXP =
          /(^#\s*encoding:.*(?:\n|r\n))|(^# coding:.*(?:\n|\r\n))|(^# -\*- coding:.*(?:\n|\r\n))|(^# -\*- encoding\s?:.*(?:\n|\r\n))|(^#\s*frozen_string_literal:.+(?:\n|\r\n))|(^# -\*- frozen_string_literal\s*:.+-\*-(?:\n|\r\n))/

        # @return [Hash{Symbol => String}]
        TYPE_MAP = {
          float: 'BigDecimal',
          decimal: 'BigDecimal',
          integer: 'Integer',
          datetime: 'ActiveSupport::TimeWithZone',
          date: 'Date',
          string: 'String',
          boolean: 'Boolean',
          text: 'String',
          jsonb: 'Hash',
          citext: 'String',
          json: 'Hash',
          bigint: 'Integer',
          uuid: 'String',
          inet: 'IPAddr'
        }
        TYPE_MAP.default = 'Object'
        TYPE_MAP.freeze

        class << self
          # @return [Hash{Class => Array<Rails::Annotate::Solargraph::Model::Scope>}]
          def scopes
            @scopes ||= {}
            @scopes
          end

          # @param name [Symbol]
          # @param model_class [Class]
          # @param proc_parameters [Array<Symbol>]
          # @param definition [String]
          def add_scope(name, model_class, proc_parameters, definition)
            scope = Scope.new(
              name: name,
              model_class: model_class,
              proc_parameters: proc_parameters,
              definition: definition
            )

            @scopes ||= {}
            @scopes[model_class] ||= []
            @scopes[model_class] << scope
            @scopes[model_class].sort_by!(&:name)
          end

          # @param klass [Class]
          # @return [String]
          def annotation_start(klass = nil)
            table_name = klass && CONFIG.schema_file? ? ":#{klass.table_name}" : ''
            "\n# %%<RailsAnnotateSolargraph:Start#{table_name}>%%"
          end

          # @param klass [Class]
          # @return [String]
          def annotation_end(klass = nil)
            table_name = klass && CONFIG.schema_file? ? ":#{klass.table_name}" : ''
            "%%<RailsAnnotateSolargraph:End#{table_name}>%%\n\n"
          end

          # @param klass [Class]
          # @return [Regexp]
          def annotation_regexp(klass = nil)
            /#{annotation_start(klass)}.*#{annotation_end(klass)}/m
          end
        end

        # @return [String]
        attr_reader :file_name

        # @return [Class]
        attr_reader :klass

        # @param klass [Class]
        def initialize(klass)
          @klass = klass
          @file_name =
            if CONFIG.schema_file?
              SCHEMA_RAILS_PATH
            else
              ::File.join(::Rails.root, MODEL_DIR, "#{klass.to_s.underscore}.rb")
            end
        end

        # @return [String]
        def annotation_start
          self.class.annotation_start(@klass)
        end

        # @return [String]
        def annotation_end
          self.class.annotation_end(@klass)
        end

        # @return [Regexp]
        def annotation_regexp
          self.class.annotation_regexp(@klass)
        end

        # @param write [Boolean]
        # @return [String] New file content.
        def annotate(write: true)
          old_content, file_content = remove_annotation write: false
          return old_content if @klass.abstract_class

          if CONFIG.annotation_position == :top
            magic_comments = file_content.scan(MAGIC_COMMENT_REGEXP).flatten.compact.join
            file_content.sub!(MAGIC_COMMENT_REGEXP, '')

            new_file_content = magic_comments + annotation + file_content
          else
            new_file_content = file_content + annotation
          end

          return new_file_content unless write
          return new_file_content if old_content == new_file_content

          write_file @file_name, new_file_content
          new_file_content
        end

        # @param write [Boolean]
        # @return [Array<String>] Old file content followed by new content.
        def remove_annotation(write: true)
          return ['', ''] unless ::File.exist?(@file_name)

          file_content = ::File.read(@file_name)
          new_file_content = file_content.sub(annotation_regexp, '')
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
            #{annotation_start}
            ##{parse_clause}
            #   class #{@klass} < #{@klass.superclass}
          DOC

          document_scopes(doc_string)
          document_relations(doc_string)
          document_fields(doc_string)

          doc_string << <<~DOC.chomp
            #   end
            # #{annotation_end}
          DOC

          # uncomment the generated annotations if they're saved in the schema file
          return doc_string.gsub(/^#\ {3}/, '').gsub(/^#\n/, "\n") if CONFIG.schema_file?

          doc_string
        end

        private

        # @return [Array<Scope>]
        def scopes
          self.class.scopes[@klass]
        end

        # @param doc_string [String]
        # @return [void]
        def document_scopes(doc_string)
          scopes&.each do |scope|
            doc_string << scope.documentation
          end
        end

        # @param doc_string [String]
        # @return [void]
        def document_relations(doc_string)
          @klass.reflections.sort.each do |attr_name, reflection|
            next document_polymorphic_relation(doc_string, attr_name, reflection) if reflection.polymorphic?

            document_relation(doc_string, attr_name, reflection)
          end
        end

        # @param doc_string [String]
        # @return [void]
        def document_fields(doc_string)
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
        end

        # @return [String, nil]
        def parse_clause
          return if CONFIG.schema_file?

          " @!parse\n#"
        end

        # @param file_name [String]
        # @return [String]
        def relative_file_name(file_name)
          file_name.delete_prefix("#{::Rails.root}/")
        end

        # @param file_name [String]
        # @param content [String]
        # @return [void]
        def write_file(file_name, content)
          ::FileUtils.touch(file_name) unless ::File.exist?(file_name)
          ::File.write(file_name, content)
          puts "modify".rjust(12).with_styles(:bold, :green) + "  #{relative_file_name(file_name)} (#{@klass})"
        end

        # @return [String]
        def klass_relation_name
          @klass.table_name[..-2]
        end

        # @param reflection [ActiveRecord::Reflection::AbstractReflection]
        # @return [Class]
        def reflection_class(reflection)
          reflection.klass
        rescue ::NameError
          Object
        end

        # @param reflection [ActiveRecord::Reflection::AbstractReflection]
        # @return [String]
        def reflection_foreign_key(reflection)
          reflection.try(:foreign_key) || '<unknown>'
        end

        # @param klass [Class]
        # @return [String]
        def class_table_name(klass)
          klass.try(:table_name) || '<unknown>'
        end

        # @param doc_string [String]
        # @param attr_name [String]
        # @param reflection [ActiveRecord::Reflection::AbstractReflection]
        # @return [void]
        def document_relation(doc_string, attr_name, reflection)
          reflection_klass = reflection_class(reflection)
          type_docstring, db_description = \
            case reflection
            when ::ActiveRecord::Reflection::BelongsToReflection
              belongs_to_description(reflection_klass,
                                     class_table_name(@klass),
                                     reflection_foreign_key(reflection))
            when ::ActiveRecord::Reflection::HasOneReflection
              has_one_description(reflection_klass,
                                  class_table_name(reflection_klass),
                                  reflection_foreign_key(reflection))
            when ::ActiveRecord::Reflection::HasManyReflection
              has_many_description(reflection_klass,
                                   class_table_name(reflection_klass),
                                   reflection_foreign_key(reflection))
            when ::ActiveRecord::Reflection::ThroughReflection
              through_description(reflection)
            else
              [::Object.to_s, '']
            end

          doc_string << <<~DOC
            #     ##{db_description}
            #     # @param val [#{type_docstring}, nil]
            #     def #{attr_name}=(val); end
            #     ##{db_description}
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

          classes_string = classes.empty? ? ::Object.to_s : classes.join(', ')
          doc_string << <<~DOC
            #     # Polymorphic relation. Database columns `#{@klass.table_name}.#{attr_name}_id` and `#{@klass.table_name}.#{attr_name}_type`.
            #     # @param val [#{classes_string}, nil]
            #     def #{attr_name}=(val); end
            #     # Polymorphic relation. Database columns `#{@klass.table_name}.#{attr_name}_id` and `#{@klass.table_name}.#{attr_name}_type`.
            #     # @return [#{classes_string}, nil]
            #     def #{attr_name}; end
          DOC
        end

        # @param reflection [ActiveRecord::Reflection::AbstractReflection]
        # @return [Array<String>]
        def through_description(reflection)
          through_klass = reflection_class(reflection.through_reflection)

          case (reflection.__send__(:delegate_reflection) rescue nil)
          when ::ActiveRecord::Reflection::HasOneReflection
            has_one_description(reflection_class(reflection.source_reflection),
                                class_table_name(through_klass),
                                reflection_foreign_key(reflection.source_reflection),
                                through: through_klass)
          when ::ActiveRecord::Reflection::HasManyReflection
            has_many_description(reflection_class(reflection.source_reflection),
                                 class_table_name(through_klass),
                                 reflection_foreign_key(reflection.source_reflection),
                                 through: through_klass)
          else
            [::Object.to_s, '']
          end
        end

        # @param through [Class, nil]
        # @return [String]
        def through_sentence(through = nil)
          return '' unless through

          " through `#{through}`"
        end

        # @param table_name [String]
        # @param foreign_key [String]
        # @param through [Class, nil]
        # @return [String]
        def column_description(table_name, foreign_key, through = nil)
          return '' if through

          " Database column `#{table_name}.#{foreign_key}`."
        end

        # @param relation [Symbol, String]
        # @param klass [Class]
        # @param table_name [String]
        # @param foreign_key [String]
        # @param through [Class, nil]
        # @return [String]
        def relation_description(relation, klass, table_name, foreign_key, through = nil)
          " `#{relation}` relation with `#{klass}`#{through_sentence(through)}.#{column_description(table_name, foreign_key, through)}"
        end


        # @param klass [Class]
        # @param table_name [String]
        # @param foreign_key [String]
        # @param :through [Class, nil]
        # @return [Array<String>] Type docstring followed by the description of the method.
        def has_many_description(klass, table_name, foreign_key, through: nil)
          type_docstring = "Array<#{klass}>"
          desc = relation_description(:has_many, klass, table_name, foreign_key, through)

          [type_docstring, desc]
        end

        # @param klass [Class]
        # @param table_name [String]
        # @param foreign_key [String]
        # @param :through [Class, nil]
        # @return [Array<String>] Type docstring followed by the description of the method.
        def has_one_description(klass, table_name, foreign_key, through: nil)
          type_docstring = klass
          desc = relation_description(:has_one, klass, table_name, foreign_key, through)

          [type_docstring, desc]
        end

        # @param klass [Class]
        # @param table_name [String]
        # @param foreign_key [String]
        # @return [Array<String>] Type docstring followed by the description of the method.
        def belongs_to_description(klass, table_name, foreign_key)
          type_docstring = klass
          desc = relation_description(:belongs_to, klass, table_name, foreign_key)

          [type_docstring, desc]
        end

        # @param attr_type [ActiveModel::Type::Value]
        # @return [String]
        def yard_type(attr_type)
          return attr_type.coder.object_class.to_s if attr_type.respond_to?(:coder) && attr_type.coder.respond_to?(:object_class)
          return 'Object' if attr_type.respond_to?(:coder) && attr_type.coder.is_a?(::ActiveRecord::Coders::JSON)

          TYPE_MAP[attr_type.type]
        end
      end
    end
  end
end
