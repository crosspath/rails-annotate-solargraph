# frozen_string_literal: true

require 'yaml'
require 'set'

module Annotate
  module Solargraph
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        desc 'Generate rails-annotate-solargraph rakefiles.'
        source_root ::File.expand_path('templates', __dir__)

        # copy rake tasks
        def copy_tasks
          template ::Rails::Annotate::Solargraph::RAKEFILE_NAME, ::File.join('lib', 'tasks', ::Rails::Annotate::Solargraph::RAKEFILE_NAME)
          template ::Rails::Annotate::Solargraph::SCHEMA_FILE_NAME, ::Rails::Annotate::Solargraph::SCHEMA_RAILS_PATH

          solargraph_config_file = ::File.join(::Rails.root, ::Rails::Annotate::Solargraph::SOLARGRAPH_FILE_NAME)
          unless ::File.exist? solargraph_config_file
            template(::Rails::Annotate::Solargraph::SOLARGRAPH_FILE_NAME, ::Rails::Annotate::Solargraph::SOLARGRAPH_FILE_PATH)
          end

          solargraph_config = ::YAML.load_file solargraph_config_file
          solargraph_config['include'] = solargraph_config['include'] || []
          solargraph_config['include'].unshift ::Rails::Annotate::Solargraph::SCHEMA_RAILS_PATH
          # make sure there are no duplicated entries
          solargraph_config['include'] = solargraph_config['include'].to_set.to_a

          ::File.write(solargraph_config_file, solargraph_config.to_yaml)
        end
      end
    end
  end
end
