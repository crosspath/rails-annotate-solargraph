# frozen_string_literal: true

require 'set'
require 'fileutils'

require_relative "solargraph/version"
require_relative "solargraph/configuration"
require_relative "solargraph/terminal_colors"
require_relative "solargraph/scope"
require_relative "solargraph/model"

begin
  require_relative "overrides"
rescue ::StandardError
  nil
end

module Rails
  module Annotate
    module Solargraph
      class Error < ::StandardError; end
      # @return [String]
      MODEL_DIR = 'app/models'
      # @return [String]
      RAKEFILE_NAME = 'rails_annotate_solargraph.rake'
      # @return [Configuration]
      CONFIG = Configuration.new
      # @return [Set<Symbol>]
      VALID_MODIFICATION_METHODS = ::Set[:annotate, :remove_annotation].freeze
      # @return [String]
      SCHEMA_CLASS_NAME = 'AnnotateSolargraphSchema'
      # @return [String]
      SOLARGRAPH_FILE_NAME = '.solargraph.yml'
      # @return [String]
      SOLARGRAPH_FILE_PATH = SOLARGRAPH_FILE_NAME
      # @return [String]
      SCHEMA_FILE_NAME = '.annotate_solargraph_schema'
      # @return [String]
      SCHEMA_RAILS_PATH = SCHEMA_FILE_NAME

      class << self
        # @return [Array<String>] Array of changed files.
        def generate
          title 'Generating model schema annotations'
          create_schema_file
          modify_models :annotate
        end

        # @return [Array<String>] Array of changed files.
        def remove
          title 'Removing model schema annotations'
          modify_models :remove_annotation
        end

        # @yieldparam [Configuration]
        def configure
          yield(CONFIG)
        end

        alias call generate

        # @return [Array<ActiveRecord::Base>]
        def model_classes
          @model_classes ||= begin
            base_abstract_class = begin
              ::ApplicationRecord
            rescue
              ::ActiveRecord::Base
            end

            extract_subclasses(base_abstract_class).sort_by(&:name)
          end
        end

        private

        # @param klass [Class]
        # @return [Array<Class>]
        def extract_subclasses(klass)
          result = []
          klass.subclasses.each do |k|
            result << k
            result.concat(extract_subclasses(k))
          end

          result
        end

        include TerminalColors

        def create_schema_file
          schema_file = ::File.join ::Rails.root, SCHEMA_RAILS_PATH
          return if ::File.exist?(schema_file)

          system 'rails g annotate:solargraph:install'
        end

        # @param method [Symbol] Name of the method that will be called on every loaded Model
        # @return [Array<String>] Array of changed files.
        def modify_models(method)
          raise Error, "Invalid method. Got `#{method.inspect}`, but expected a member of `#{VALID_MODIFICATION_METHODS}`" \
            unless VALID_MODIFICATION_METHODS.include? method

          changed_files = []
          model_files = ::Dir[::File.join(::Rails.root, MODEL_DIR, '**/*.rb')].map { |file| file.sub("#{::Rails.root}/", '') }.to_set

          require_relative "overrides"
          ::Rails.application.eager_load!
          model_classes.each do |subclass|
            subclass_file = ::File.join MODEL_DIR, "#{subclass.to_s.underscore}.rb"
            next unless model_files.include? subclass_file

            Model.new(subclass).public_send(method)
            changed_files << subclass_file
          end

          changed_files
        end
      end
    end
  end
end
