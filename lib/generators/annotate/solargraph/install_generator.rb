require 'rails/annotate/solargraph'

module Annotate
  module Solargraph
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        desc 'Generate rails-annotate-solargraph rakefiles.'
        source_root ::File.expand_path('templates', __dir__)

        # copy rake tasks
        def copy_tasks
          template ::Rails::Annotate::Solargraph::RAKEFILE_NAME, ::Rails::Annotate::Solargraph::RAKEFILE_NAME
        end
      end
    end
  end
end
