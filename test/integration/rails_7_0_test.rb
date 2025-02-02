# frozen_string_literal: true

require "test_helper"
require 'fileutils'
require 'byebug'

class Rails70Test < ::Minitest::Test
  RAKEFILE_PATH = "lib/tasks/#{::Rails::Annotate::Solargraph::RAKEFILE_NAME}"
  RAILS_PROJECT_PATH = 'test/dummy/rails_7_0'
  MODEL_FILES = %w[app/models/author.rb app/models/book.rb app/models/essay.rb app/models/image.rb app/models/publisher.rb].sort.freeze

  def setup
    @schema_file = false
    @original_pwd = ::Dir.pwd
    ::Dir.chdir RAILS_PROJECT_PATH
    @git = ::Git.init(::Dir.pwd)
    @git.add
    @git.commit('.')
    assert @git.diff.none?
    assert system 'TEST=true bundle exec rails db:drop db:setup'
  end

  def teardown
    @schema_file = false
    @git.clean(force: true)
    @git.reset_hard
    @git = nil
    ::FileUtils.rm_rf('.git')
    ::Dir.chdir @original_pwd
  end

  def test_generate_rakefile
    assert @git.diff.none?
    assert system 'TEST=true rails g annotate:solargraph:install'
    @git.add
    assert_equal 3, @git.diff.entries.size

    diff = file_diff RAKEFILE_PATH
    assert_equal RAKEFILE_PATH, diff.path
    assert_equal 'new', diff.type

    diff = file_diff ::Rails::Annotate::Solargraph::SCHEMA_RAILS_PATH
    assert_equal ::Rails::Annotate::Solargraph::SCHEMA_RAILS_PATH, diff.path
    assert_equal 'new', diff.type

    diff = file_diff ::Rails::Annotate::Solargraph::SOLARGRAPH_FILE_NAME
    assert_equal ::Rails::Annotate::Solargraph::SOLARGRAPH_FILE_NAME, diff.path
    assert_equal 'new', diff.type
  end

  def test_annotate_models
    assert system 'bundle exec rails g annotate:solargraph:install'
    assert system 'bundle exec rake annotate:solargraph:generate'
    assert_equal 5, @git.diff.entries.size
    assert_equal MODEL_FILES, @git.diff.entries.map(&:path).sort

    verify_annotations
  end

  def test_remove_annotations
    assert system 'bundle exec rails g annotate:solargraph:install'
    assert system 'bundle exec rake annotate:solargraph:generate'
    assert_equal 5, @git.diff.entries.size
    assert_equal MODEL_FILES, @git.diff.entries.map(&:path).sort

    assert system 'bundle exec rake annotate:solargraph:remove'
    assert @git.diff.none?
  end

  def test_annotate_models_in_schema_file
    assert system 'bundle exec rails g annotate:solargraph:install'
    assert system 'SCHEMA_FILE=true bundle exec rake annotate:solargraph:generate'
    @git.add schema_file_name
    assert_equal 1, @git.diff.entries.size
    assert_equal schema_file_name, @git.diff.entries.first.path

    @schema_file = true
    verify_annotations
  end

  def test_annotate_after_migration
    assert system 'bundle exec rails g annotate:solargraph:install'
    assert system 'bundle exec rails g model NewModel'
    assert system 'TEST=true bundle exec rails db:migrate'

    @git.add 'app/models/new_model.rb'
    assert_equal 7, @git.diff.entries.size

    diff = file_diff 'app/models/new_model.rb'
    assert_equal 'app/models/new_model.rb', diff.path
    assert_equal 'new', diff.type
    expected_patch = model_patch 'app/models/new_model.rb'
    assert diff.patch.include? expected_patch

    verify_annotations
  end

  def test_annotate_after_migration_in_schema_file
    assert system 'bundle exec rails g annotate:solargraph:install'
    assert system 'bundle exec rails g model NewModel'
    assert system 'TEST=true SCHEMA_FILE=true bundle exec rails db:migrate'

    @git.add 'app/models/new_model.rb'
    @git.add schema_file_name
    assert_equal 3, @git.diff.entries.size

    @schema_file = true
    diff = file_diff 'app/models/new_model.rb'
    assert_equal schema_file_name, diff.path
    assert_equal 'new', diff.type
    expected_patch = model_patch 'app/models/new_model.rb'
    assert diff.patch.include? expected_patch

    verify_annotations
  end

  private

  def model_patch(model_file_name)
    result = PATCHES.fetch model_file_name
    return result.gsub(/^\+#\ {3}/, '+').gsub(/^\+#\n/, "+\n") if @schema_file

    result
  end

  def schema_file_name
    ::Rails::Annotate::Solargraph::SCHEMA_RAILS_PATH
  end

  def file_diff(file_name)
    file_name = schema_file_name if @schema_file
    @git.diff.entries.find { _1.path == file_name }
  end

  def verify_annotations
    diff = file_diff 'app/models/author.rb'
    expected_patch = model_patch 'app/models/author.rb'

    assert diff.patch.include? expected_patch

    diff = file_diff 'app/models/book.rb'
    expected_patch = model_patch 'app/models/book.rb'

    assert diff.patch.include? expected_patch

    diff = file_diff 'app/models/essay.rb'
    expected_patch = model_patch 'app/models/essay.rb'

    assert diff.patch.include? expected_patch

    diff = file_diff 'app/models/image.rb'
    expected_patch = model_patch 'app/models/image.rb'

    assert diff.patch.include? expected_patch

    diff = file_diff 'app/models/publisher.rb'
    expected_patch = model_patch 'app/models/publisher.rb'

    assert diff.patch.include? expected_patch
  end

  PATCHES = {
    'app/models/new_model.rb' => <<~PATCH.chomp,
      +#   class NewModel < ApplicationRecord
      +#     # Database column `new_models.id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def id=(val); end
      +#     # Database column `new_models.id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def id; end
      +#     # Database column `new_models.created_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def created_at=(val); end
      +#     # Database column `new_models.created_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def created_at; end
      +#     # Database column `new_models.updated_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at=(val); end
      +#     # Database column `new_models.updated_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at; end
      +#   end
    PATCH
    'app/models/author.rb' => <<~PATCH.chomp,
      +#   class Author < AbstractRecord
      +#     # Scope `:since`.
      +#     #
      +#     #     scope :since, ->(ago) { where("created_at > ?", ago) }
      +#     #
      +#     # @return [Array<Author>, nil]
      +#     def self.since(ago); end
      +#     # `has_many` relation with `Book`. Database column `books.author_id`.
      +#     # @param val [Array<Book>, nil]
      +#     def books=(val); end
      +#     # `has_many` relation with `Book`. Database column `books.author_id`.
      +#     # @return [Array<Book>, nil]
      +#     def books; end
      +#     # `has_many` relation with `Essay`. Database column `essays.author_id`.
      +#     # @param val [Array<Essay>, nil]
      +#     def essays=(val); end
      +#     # `has_many` relation with `Essay`. Database column `essays.author_id`.
      +#     # @return [Array<Essay>, nil]
      +#     def essays; end
      +#     # `has_one` relation with `Image`. Database column `images.imageable_id`.
      +#     # @param val [Image, nil]
      +#     def image=(val); end
      +#     # `has_one` relation with `Image`. Database column `images.imageable_id`.
      +#     # @return [Image, nil]
      +#     def image; end
      +#     # Database column `authors.id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def id=(val); end
      +#     # Database column `authors.id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def id; end
      +#     # Database column `authors.first_name`, type: `string`.
      +#     # @param val [String, nil]
      +#     def first_name=(val); end
      +#     # Database column `authors.first_name`, type: `string`.
      +#     # @return [String, nil]
      +#     def first_name; end
      +#     # Database column `authors.last_name`, type: `string`.
      +#     # @param val [String, nil]
      +#     def last_name=(val); end
      +#     # Database column `authors.last_name`, type: `string`.
      +#     # @return [String, nil]
      +#     def last_name; end
      +#     # Database column `authors.created_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def created_at=(val); end
      +#     # Database column `authors.created_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def created_at; end
      +#     # Database column `authors.updated_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at=(val); end
      +#     # Database column `authors.updated_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at; end
      +#   end
    PATCH
    'app/models/book.rb' => <<~PATCH.chomp,
      +#   class Book < AbstractRecord
      +#     # Scope `:expensive`.
      +#     #
      +#     #     scope :expensive, -> { where('amount > ?', 250) }
      +#     #
      +#     # @return [Array<Book>, nil]
      +#     def self.expensive(); end
      +#     # Scope `:hard_cover`.
      +#     #
      +#     #     scope :hard_cover, -> { where(hard_cover: true) }
      +#     #
      +#     # @return [Array<Book>, nil]
      +#     def self.hard_cover(); end
      +#     # Scope `:more_expensive_than`.
      +#     #
      +#     #     scope :more_expensive_than, proc { |price|
      +#     #       where('amount > ?', price)
      +#     #     }
      +#     #
      +#     # @return [Array<Book>, nil]
      +#     def self.more_expensive_than(price); end
      +#     # Scope `:since`.
      +#     #
      +#     #     scope(:since, lambda do |ago|
      +#     #       next unless ago
      +#     #     
      +#     #       where("created_at > ?", ago)
      +#     #     end)
      +#     #
      +#     # @return [Array<Book>, nil]
      +#     def self.since(ago); end
      +#     # Scope `:soft_cover`.
      +#     #
      +#     #     scope :soft_cover, -> { where(hard_cover: false) }
      +#     #
      +#     # @return [Array<Book>, nil]
      +#     def self.soft_cover(); end
      +#     # `belongs_to` relation with `Author`. Database column `books.author_id`.
      +#     # @param val [Author, nil]
      +#     def author=(val); end
      +#     # `belongs_to` relation with `Author`. Database column `books.author_id`.
      +#     # @return [Author, nil]
      +#     def author; end
      +#     # `has_one` relation with `Image`. Database column `images.imageable_id`.
      +#     # @param val [Image, nil]
      +#     def image=(val); end
      +#     # `has_one` relation with `Image`. Database column `images.imageable_id`.
      +#     # @return [Image, nil]
      +#     def image; end
      +#     # `belongs_to` relation with `Publisher`. Database column `books.publisher_id`.
      +#     # @param val [Publisher, nil]
      +#     def publisher=(val); end
      +#     # `belongs_to` relation with `Publisher`. Database column `books.publisher_id`.
      +#     # @return [Publisher, nil]
      +#     def publisher; end
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
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def created_at=(val); end
      +#     # Database column `books.created_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def created_at; end
      +#     # Database column `books.updated_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at=(val); end
      +#     # Database column `books.updated_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at; end
      +#     # Database column `books.author_id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def author_id=(val); end
      +#     # Database column `books.author_id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def author_id; end
      +#     # Database column `books.publisher_id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def publisher_id=(val); end
      +#     # Database column `books.publisher_id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def publisher_id; end
      +#   end
    PATCH
    'app/models/essay.rb' => <<~PATCH.chomp,
      +#   class Essay < ApplicationRecord
      +#     # Scope `:since`.
      +#     #
      +#     #     scope :since, ->(ago) { where("created_at > ?", ago) }
      +#     #
      +#     # @return [Array<Essay>, nil]
      +#     def self.since(ago); end
      +#     # `belongs_to` relation with `Author`. Database column `essays.author_id`.
      +#     # @param val [Author, nil]
      +#     def author=(val); end
      +#     # `belongs_to` relation with `Author`. Database column `essays.author_id`.
      +#     # @return [Author, nil]
      +#     def author; end
      +#     # `has_one` relation with `Image` through `Author`.
      +#     # @param val [Image, nil]
      +#     def image=(val); end
      +#     # `has_one` relation with `Image` through `Author`.
      +#     # @return [Image, nil]
      +#     def image; end
      +#     # Database column `essays.id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def id=(val); end
      +#     # Database column `essays.id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def id; end
      +#     # Database column `essays.content`, type: `text`.
      +#     # @param val [String, nil]
      +#     def content=(val); end
      +#     # Database column `essays.content`, type: `text`.
      +#     # @return [String, nil]
      +#     def content; end
      +#     # Database column `essays.title`, type: `string`.
      +#     # @param val [String, nil]
      +#     def title=(val); end
      +#     # Database column `essays.title`, type: `string`.
      +#     # @return [String, nil]
      +#     def title; end
      +#     # Database column `essays.author_id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def author_id=(val); end
      +#     # Database column `essays.author_id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def author_id; end
      +#     # Database column `essays.created_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def created_at=(val); end
      +#     # Database column `essays.created_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def created_at; end
      +#     # Database column `essays.updated_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at=(val); end
      +#     # Database column `essays.updated_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at; end
      +#   end
    PATCH
    'app/models/image.rb' => <<~PATCH.chomp,
      +#   class Image < ApplicationRecord
      +#     # Scope `:between`.
      +#     #
      +#     #     scope :between, ->(from, to) { where("created_at > ? AND created_at < ?", from, to) }
      +#     #
      +#     # @return [Array<Image>, nil]
      +#     def self.between(from, to); end
      +#     # Scope `:since`.
      +#     #
      +#     #     scope :since, ->(ago) { where("created_at > ?", ago) }
      +#     #
      +#     # @return [Array<Image>, nil]
      +#     def self.since(ago); end
      +#     # Polymorphic relation. Database columns `images.imageable_id` and `images.imageable_type`.
      +#     # @param val [Author, Book, nil]
      +#     def imageable=(val); end
      +#     # Polymorphic relation. Database columns `images.imageable_id` and `images.imageable_type`.
      +#     # @return [Author, Book, nil]
      +#     def imageable; end
      +#     # Database column `images.id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def id=(val); end
      +#     # Database column `images.id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def id; end
      +#     # Database column `images.content`, type: `text`.
      +#     # @param val [String, nil]
      +#     def content=(val); end
      +#     # Database column `images.content`, type: `text`.
      +#     # @return [String, nil]
      +#     def content; end
      +#     # Database column `images.imageable_id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def imageable_id=(val); end
      +#     # Database column `images.imageable_id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def imageable_id; end
      +#     # Database column `images.imageable_type`, type: `string`.
      +#     # @param val [String, nil]
      +#     def imageable_type=(val); end
      +#     # Database column `images.imageable_type`, type: `string`.
      +#     # @return [String, nil]
      +#     def imageable_type; end
      +#     # Database column `images.created_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def created_at=(val); end
      +#     # Database column `images.created_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def created_at; end
      +#     # Database column `images.updated_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at=(val); end
      +#     # Database column `images.updated_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at; end
      +#   end
    PATCH
    'app/models/publisher.rb' => <<~PATCH.chomp,
      +#   class Publisher < ApplicationRecord
      +#     # Scope `:since`.
      +#     #
      +#     #     scope :since, ->(ago) { where("created_at > ?", ago) }
      +#     #
      +#     # @return [Array<Publisher>, nil]
      +#     def self.since(ago); end
      +#     # `has_many` relation with `Author` through `Book`.
      +#     # @param val [Array<Author>, nil]
      +#     def authors=(val); end
      +#     # `has_many` relation with `Author` through `Book`.
      +#     # @return [Array<Author>, nil]
      +#     def authors; end
      +#     # `has_many` relation with `Book`. Database column `books.publisher_id`.
      +#     # @param val [Array<Book>, nil]
      +#     def books=(val); end
      +#     # `has_many` relation with `Book`. Database column `books.publisher_id`.
      +#     # @return [Array<Book>, nil]
      +#     def books; end
      +#     # Database column `publishers.id`, type: `integer`.
      +#     # @param val [Integer, nil]
      +#     def id=(val); end
      +#     # Database column `publishers.id`, type: `integer`.
      +#     # @return [Integer, nil]
      +#     def id; end
      +#     # Database column `publishers.name`, type: `string`.
      +#     # @param val [String, nil]
      +#     def name=(val); end
      +#     # Database column `publishers.name`, type: `string`.
      +#     # @return [String, nil]
      +#     def name; end
      +#     # Database column `publishers.created_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def created_at=(val); end
      +#     # Database column `publishers.created_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def created_at; end
      +#     # Database column `publishers.updated_at`, type: `datetime`.
      +#     # @param val [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at=(val); end
      +#     # Database column `publishers.updated_at`, type: `datetime`.
      +#     # @return [ActiveSupport::TimeWithZone, nil]
      +#     def updated_at; end
      +#   end
    PATCH
  }
end
