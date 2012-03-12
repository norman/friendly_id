require File.expand_path("../helper.rb", __FILE__)

class StiTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core
  include FriendlyId::Test::Shared::Slugged

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
  end

  class Editorialist < Journalist
  end

  def model_class
    Editorialist
  end

  test "friendly_id should accept a base and a hash with single table inheritance" do
    abstract_klass = Class.new(ActiveRecord::Base) do
      def self.table_exists?; false end
      extend FriendlyId
      friendly_id :foo, :use => :slugged, :slug_column => :bar
    end
    klass = Class.new(abstract_klass)
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end

  test "the configuration's model_class should be the class, not the base_class" do
    assert_equal StiTest::Editorialist, model_class.friendly_id_config.model_class
  end

  test "friendly_id should accept a block with single table inheritance" do
    abstract_klass = Class.new(ActiveRecord::Base) do
      def self.table_exists?; false end
      extend FriendlyId
      friendly_id :foo do |config|
        config.use :slugged
        config.base = :foo
        config.slug_column = :bar
      end
    end
    klass = Class.new(abstract_klass)
    assert klass < FriendlyId::Slugged
    assert_equal :foo, klass.friendly_id_config.base
    assert_equal :bar, klass.friendly_id_config.slug_column
  end

  test "friendly_id slugs should not clash with eachother" do
    journalist  = Journalist.create! :name => 'foo bar'
    editoralist = Editorialist.create! :name => 'foo bar'

    assert_equal 'foo-bar', journalist.slug
    assert_equal 'foo-bar--2', editoralist.slug
  end

end
