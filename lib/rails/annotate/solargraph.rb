# frozen_string_literal: true

require 'set'

require_relative "solargraph/version"
require_relative "solargraph/configuration"
require_relative "solargraph/model"

module Rails
  module Annotate
    module Solargraph
      class Error < ::StandardError; end
      MODEL_DIR = 'app/models'
      RAKEFILE_NAME = 'rails_annotate_solargraph.rake'
      # @return [Configuration]
      CONFIG = Configuration.new

      class << self
        # @return [Array<String>] Array of changed files.
        def generate
          changed_files = []
          model_files = ::Dir[::File.join(::Rails.root, MODEL_DIR, '**/*.rb')].map { |file| file.sub("#{::Rails.root}/", '') }.to_set

          ::Rails.application.eager_load!
          (::ApplicationRecord rescue ::ActiveRecord::Base).subclasses.each do |subclass|
            subclass_file = ::File.join MODEL_DIR, "#{subclass.to_s.underscore}.rb"
            next unless model_files.include? subclass_file

            Model.new(subclass).annotate
            changed_files << subclass_file
          end

          changed_files
        end

        # @return [Array<String>] Array of changed files.
        def remove
          changed_files = []
          model_files = ::Dir[::File.join(::Rails.root, MODEL_DIR, '**/*.rb')].to_set

          (::ApplicationRecord rescue ::ActiveRecord::Base).subclasses.each do |subclass|
            subclass_file = ::File.join MODEL_DIR, "#{subclass.to_s.underscore}.rb"
            next unless model_files.include? subclass_file

            Model.new(subclass).remove_annotation
            changed_files << subclass_file
          end

          changed_files
        end

        # @yieldparam [Configuration]
        def configure
          yield(CONFIG)
        end

        alias call generate
      end
    end
  end
end
