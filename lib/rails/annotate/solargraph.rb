# frozen_string_literal: true

require 'set'

require_relative "solargraph/version"
require_relative "solargraph/active_record_type_refinement"
require_relative "solargraph/model"

module Rails
  module Annotate
    module Solargraph
      class Error < ::StandardError; end
      MODEL_DIR = 'app/models'

      class << self
        # @return [Array<String>] Array of changed files.
        def generate
          ::Dir.cwd MODEL_DIR
          model_files = ::Dir['**/*.rb'].to_set
          changed_files = []

          (::ApplicationRecord rescue ::ActiveRecord::Base).subclasses.each do |subclass|
            subclass_file = "#{subclass.to_s.underscore}.rb"
            next unless model_files.include? subclass_file

            Model.new(subclass).annotate
            changed_files << ::File.join(MODEL_DIR, subclass_file)
          end

          changed_files
        end

        alias call generate
      end
    end
  end
end
