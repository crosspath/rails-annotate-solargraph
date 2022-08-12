# frozen_string_literal: true

require "test_helper"

module Rails::Annotate
  module Solargraph
    class ScopeTest < ::Minitest::Test
      class TestClass; end

      def test_document_single_line_scope
        scope = Scope.new(
          name: :since,
          model_class: TestClass,
          proc_parameters: %i[ago],
          definition: <<~RUBY.chomp
            scope :since, ->(ago) { where("created_at > ?", ago) }
          RUBY
        )

        assert_equal <<~DOC, scope.documentation
          #     # Scope `:since`.
          #     #
          #     #     scope :since, ->(ago) { where("created_at > ?", ago) }
          #     #
          #     # @return [Array<Rails::Annotate::Solargraph::ScopeTest::TestClass>, nil]
          #     def self.since(ago); end
        DOC
      end

      def test_document_multi_line_scope
        scope = Scope.new(
          name: :some_scope,
          model_class: Object,
          proc_parameters: %i[now then],
          definition: <<~RUBY.chomp
            scope(:some_scope, lambda do |now, then|
              next unless now

              where("created_at > ?", now)
            end)
          RUBY
        )

        assert_equal <<~DOC, scope.documentation
          #     # Scope `:some_scope`.
          #     #
          #     #     scope(:some_scope, lambda do |now, then|
          #     #       next unless now
          #     #     
          #     #       where("created_at > ?", now)
          #     #     end)
          #     #
          #     # @return [Array<Object>, nil]
          #     def self.some_scope(now, then); end
        DOC
      end
    end
  end
end
