# frozen_string_literal: true

require "test_helper"

module Rails
  module Annotate
    module Solargraph
      class Rails70Test < ::Minitest::Test
        def setup
          @original_pwd = ::Dir.pwd
          ::Dir.chdir 'test/rails_7_0'
          @git = ::Git.open(::Dir.pwd)
          @git.clean(force: true)
        end

        def teardown
          # @git.
          ::Dir.chdir @original_pwd
        end

        def test_generator
          rakefile_path = "lib/tasks/#{RAKEFILE_NAME}"
          assert @git.diff.none?
          assert !::File.exist?(rakefile_path)
          assert system 'rails g annotate:solargraph:install'
          debugger
          assert ::File.exist?(rakefile_path)
        end

      end
    end
  end
end