require File.expand_path("../helper.rb", __FILE__)

class Journalist < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class Article < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class SluggedTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core
  include FriendlyId::Test::Shared::Slugged

  def model_class
    Journalist
  end

  test "should not allow reserved words in resulting slug" do
    ["new", "New", "NEW"].each do |word|
      transaction do
        assert_raises(ActiveRecord::RecordInvalid) {model_class.create! :name => word}
      end
    end
  end

end

class SlugSequencerTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  test "should quote column names" do
    model_class            = Class.new(ActiveRecord::Base)
    model_class.table_name = "journalists"
    model_class.extend FriendlyId
    model_class.friendly_id :name, :use => :slugged, :slug_column => "strange name"
    begin
      with_instance_of(model_class) {|record| assert model_class.find(record.friendly_id)}
    rescue ActiveRecord::StatementInvalid
      flunk "column name was not quoted"
    end
  end
end

class SlugSeparatorTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged, :sequence_separator => ":"
  end

  def model_class
    Journalist
  end

  test "should increment sequence with configured sequence separator" do
    with_instance_of model_class do |record|
      record2 = model_class.create! :name => record.name
      assert record2.friendly_id.match(/:2\z/)
    end
  end

  test "should detect when a sequenced slug has changed" do
    with_instance_of model_class do |record|
      record2 = model_class.create! :name => record.name
      assert !record2.should_generate_new_friendly_id?
      record2.name = "hello world"
      assert record2.should_generate_new_friendly_id?
    end
  end
end

class DefaultScopeTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
    default_scope :order => 'id ASC', :conditions => { :active => true }
  end

  test "friendly_id should correctly sequence a default_scoped ordered table" do
    transaction do
      3.times { assert Journalist.create :name => "a", :active => true }
    end
  end

  test "friendly_id should correctly sequence a default_scoped scoped table" do
    transaction do
      assert Journalist.create :name => "a", :active => false
      assert Journalist.create :name => "a", :active => true
    end
  end
end

class SluggedRegressionsTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  def model_class
    Journalist
  end

  test "should increment the slug sequence for duplicate friendly ids beyond 10" do
    with_instance_of model_class do |record|
      (2..12).each do |i|
        r = model_class.create! :name => record.name
        assert r.friendly_id.match(/#{i}\z/)
      end
    end
  end
end
