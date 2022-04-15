# frozen_string_literal: true

require "test_helper"

class Rails::Annotate::SolargraphTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rails::Annotate::Solargraph::VERSION
  end

  def test_configure
    assert_equal :bottom, Rails::Annotate::Solargraph::CONFIG.annotation_position
    Rails::Annotate::Solargraph.configure do |conf|
      assert conf.is_a?(::Rails::Annotate::Solargraph::Configuration)
      assert_raises Rails::Annotate::Solargraph::Error do
        conf.annotation_position = :incorrect
      end
      assert_equal :bottom, conf.annotation_position
      conf.annotation_position = :top
      assert_equal :top, conf.annotation_position
    end
    assert_equal :top, Rails::Annotate::Solargraph::CONFIG.annotation_position
  end
end
