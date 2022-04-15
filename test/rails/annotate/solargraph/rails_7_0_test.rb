# frozen_string_literal: true

require "test_helper"

module Rails
  module Annotate
    module Solargraph
      class Rails70Test < ::Minitest::Test
        RAKEFILE_PATH = "lib/tasks/#{RAKEFILE_NAME}"

        def setup
          @original_verbose = $VERBOSE
          $VERBOSE = nil
          @original_pwd = ::Dir.pwd
          ::Dir.chdir 'test/rails_7_0'
          @git = ::Git.open(::Dir.pwd)
          assert @git.diff.none?
        end

        def teardown
          @git.clean(force: true)
          @git.reset_hard('main')
          ::Dir.chdir @original_pwd
          $VERBOSE = @original_verbose
        end

        def test_generate_rakefile
          assert !::File.exist?(RAKEFILE_PATH)
          assert system 'rails g annotate:solargraph:install'
          assert ::File.exist?(RAKEFILE_PATH)
          assert @git.diff.none?
        end

        def test_annotate_models
          assert system 'bundle exec rails g annotate:solargraph:install'
          assert system 'bundle exec rake annotate:solargraph:generate'
          assert_equal 1, @git.diff.entries.size
          diff = @git.diff.entries.first
          assert_equal 'modified', diff.type
          assert_equal 'app/models/book.rb', diff.path
          expected_patch = <<~PATCH.chomp
            +
            +# %%<RailsAnnotateSolargraph:Start>%%
            +# @!parse
            +#   class Book < ApplicationRecord
            +#     # Database column `books.id`, type: `integer`.
            +#     # @param val [Integer, nil]
            +#     def id=(val); end
            +#     # Database column `books.id`, type: `integer`.
            +#     # @return [Integer, nil]
            +#     def id; end
            +#     # Database column `books.hash`, type: `text`.
            +#     # @param val [Hash, nil]
            +#     def hash=(val); end
            +#     # Database column `books.hash`, type: `text`.
            +#     # @return [Hash, nil]
            +#     def hash; end
            +#     # Database column `books.array`, type: `text`.
            +#     # @param val [Array, nil]
            +#     def array=(val); end
            +#     # Database column `books.array`, type: `text`.
            +#     # @return [Array, nil]
            +#     def array; end
            +#     # Database column `books.openstruct`, type: `text`.
            +#     # @param val [OpenStruct, nil]
            +#     def openstruct=(val); end
            +#     # Database column `books.openstruct`, type: `text`.
            +#     # @return [OpenStruct, nil]
            +#     def openstruct; end
            +#     # Database column `books.integer`, type: `integer`.
            +#     # @param val [Integer, nil]
            +#     def integer=(val); end
            +#     # Database column `books.integer`, type: `integer`.
            +#     # @return [Integer, nil]
            +#     def integer; end
            +#     # Database column `books.price`, type: `decimal`.
            +#     # @param val [BigDecimal, nil]
            +#     def price=(val); end
            +#     # Database column `books.price`, type: `decimal`.
            +#     # @return [BigDecimal, nil]
            +#     def price; end
            +#     # Database column `books.hard_cover`, type: `boolean`.
            +#     # @param val [Boolean, nil]
            +#     def hard_cover=(val); end
            +#     # Database column `books.hard_cover`, type: `boolean`.
            +#     # @return [Boolean, nil]
            +#     def hard_cover; end
            +#     # Database column `books.title`, type: `string`.
            +#     # @param val [String, nil]
            +#     def title=(val); end
            +#     # Database column `books.title`, type: `string`.
            +#     # @return [String, nil]
            +#     def title; end
            +#     # Database column `books.created_at`, type: `datetime`.
            +#     # @param val [Time, nil]
            +#     def created_at=(val); end
            +#     # Database column `books.created_at`, type: `datetime`.
            +#     # @return [Time, nil]
            +#     def created_at; end
            +#     # Database column `books.updated_at`, type: `datetime`.
            +#     # @param val [Time, nil]
            +#     def updated_at=(val); end
            +#     # Database column `books.updated_at`, type: `datetime`.
            +#     # @return [Time, nil]
            +#     def updated_at; end
            +#   end
            +# %%<RailsAnnotateSolargraph:End>%%
            +
          PATCH

          assert diff.patch.include? expected_patch
        end

        def test_remove_annotations
          assert system 'bundle exec rails g annotate:solargraph:install'
          assert system 'bundle exec rake annotate:solargraph:generate'
          assert_equal 1, @git.diff.entries.size
          diff = @git.diff.entries.first
          assert_equal 'modified', diff.type
          assert_equal 'app/models/book.rb', diff.path

          assert system 'bundle exec rake annotate:solargraph:remove'
          assert @git.diff.none?
        end

        def test_annotate_after_migration
          assert system 'bundle exec rails db:drop db:setup'
          assert system 'bundle exec rails g annotate:solargraph:install'
          assert system 'bundle exec rails g model NewModel'
          assert system 'bundle exec rails db:migrate'

          @git.add 'app/models/new_model.rb'
          assert_equal 3, @git.diff.entries.size
          diff = @git.diff.entries
          new_model_diff = diff.find { |d| d.type == 'new' }
          assert_equal 'app/models/new_model.rb', new_model_diff.path
          expected_patch = <<~PATCH.chomp
            +
            +# %%<RailsAnnotateSolargraph:Start>%%
            +# @!parse
            +#   class NewModel < ApplicationRecord
            +#     # Database column `new_models.id`, type: `integer`.
            +#     # @param val [Integer, nil]
            +#     def id=(val); end
            +#     # Database column `new_models.id`, type: `integer`.
            +#     # @return [Integer, nil]
            +#     def id; end
            +#     # Database column `new_models.created_at`, type: `datetime`.
            +#     # @param val [Time, nil]
            +#     def created_at=(val); end
            +#     # Database column `new_models.created_at`, type: `datetime`.
            +#     # @return [Time, nil]
            +#     def created_at; end
            +#     # Database column `new_models.updated_at`, type: `datetime`.
            +#     # @param val [Time, nil]
            +#     def updated_at=(val); end
            +#     # Database column `new_models.updated_at`, type: `datetime`.
            +#     # @return [Time, nil]
            +#     def updated_at; end
            +#   end
            +# %%<RailsAnnotateSolargraph:End>%%
            +
          PATCH
          assert new_model_diff.patch.include? expected_patch

          book_diff = diff.find { |d| d.path == 'app/models/book.rb' }
          assert_equal 'modified', book_diff.type
          expected_patch = <<~PATCH.chomp
            +
            +# %%<RailsAnnotateSolargraph:Start>%%
            +# @!parse
            +#   class Book < ApplicationRecord
            +#     # Database column `books.id`, type: `integer`.
            +#     # @param val [Integer, nil]
            +#     def id=(val); end
            +#     # Database column `books.id`, type: `integer`.
            +#     # @return [Integer, nil]
            +#     def id; end
            +#     # Database column `books.hash`, type: `text`.
            +#     # @param val [Hash, nil]
            +#     def hash=(val); end
            +#     # Database column `books.hash`, type: `text`.
            +#     # @return [Hash, nil]
            +#     def hash; end
            +#     # Database column `books.array`, type: `text`.
            +#     # @param val [Array, nil]
            +#     def array=(val); end
            +#     # Database column `books.array`, type: `text`.
            +#     # @return [Array, nil]
            +#     def array; end
            +#     # Database column `books.openstruct`, type: `text`.
            +#     # @param val [OpenStruct, nil]
            +#     def openstruct=(val); end
            +#     # Database column `books.openstruct`, type: `text`.
            +#     # @return [OpenStruct, nil]
            +#     def openstruct; end
            +#     # Database column `books.integer`, type: `integer`.
            +#     # @param val [Integer, nil]
            +#     def integer=(val); end
            +#     # Database column `books.integer`, type: `integer`.
            +#     # @return [Integer, nil]
            +#     def integer; end
            +#     # Database column `books.price`, type: `decimal`.
            +#     # @param val [BigDecimal, nil]
            +#     def price=(val); end
            +#     # Database column `books.price`, type: `decimal`.
            +#     # @return [BigDecimal, nil]
            +#     def price; end
            +#     # Database column `books.hard_cover`, type: `boolean`.
            +#     # @param val [Boolean, nil]
            +#     def hard_cover=(val); end
            +#     # Database column `books.hard_cover`, type: `boolean`.
            +#     # @return [Boolean, nil]
            +#     def hard_cover; end
            +#     # Database column `books.title`, type: `string`.
            +#     # @param val [String, nil]
            +#     def title=(val); end
            +#     # Database column `books.title`, type: `string`.
            +#     # @return [String, nil]
            +#     def title; end
            +#     # Database column `books.created_at`, type: `datetime`.
            +#     # @param val [Time, nil]
            +#     def created_at=(val); end
            +#     # Database column `books.created_at`, type: `datetime`.
            +#     # @return [Time, nil]
            +#     def created_at; end
            +#     # Database column `books.updated_at`, type: `datetime`.
            +#     # @param val [Time, nil]
            +#     def updated_at=(val); end
            +#     # Database column `books.updated_at`, type: `datetime`.
            +#     # @return [Time, nil]
            +#     def updated_at; end
            +#   end
            +# %%<RailsAnnotateSolargraph:End>%%
            +
          PATCH

          assert book_diff.patch.include? expected_patch
        end
      end
    end
  end
end
