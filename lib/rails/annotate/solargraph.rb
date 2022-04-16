# frozen_string_literal: true

require 'set'

require_relative "solargraph/version"
require_relative "solargraph/configuration"
require_relative "solargraph/terminal_colors"
require_relative "solargraph/model"

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

      class << self
        # @return [Array<String>] Array of changed files.
        def generate
          title 'Generating model schema annotations'
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
          @model_classes ||= (::ApplicationRecord rescue ::ActiveRecord::Base).subclasses.sort_by(&:name)
        end

        private

        include TerminalColors

        # @param method [Symbol] Name of the method that will be called on every loaded Model
        # @return [Array<String>] Array of changed files.
        def modify_models(method)
          raise Error, "Invalid method. Got `#{method.inspect}`, but expected a member of `#{VALID_MODIFICATION_METHODS}`" \
            unless VALID_MODIFICATION_METHODS.include? method

          changed_files = []
          model_files = ::Dir[::File.join(::Rails.root, MODEL_DIR, '**/*.rb')].map { |file| file.sub("#{::Rails.root}/", '') }.to_set

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
