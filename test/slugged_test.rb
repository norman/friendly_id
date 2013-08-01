require "helper"

class Journalist < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class Article < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

class Novelist < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged, :sequence_separator => '_'

  def normalize_friendly_id(string)
    super.gsub("-", "_")
  end
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

  test "should allow validations on the slug" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "articles"
      extend FriendlyId
      friendly_id :name, :use => :slugged
      validates_length_of :slug, :maximum => 1
      def self.name
        "Article"
      end
    end
    instance = model_class.new :name => "hello"
    refute instance.valid?
  end

  test "should allow nil slugs" do
    transaction do
      m1 = model_class.create!
      model_class.create!
      assert_nil m1.slug
    end
  end

  test "should not break validates_uniqueness_of" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "journalists"
      extend FriendlyId
      friendly_id :name, :use => :slugged
      validates_uniqueness_of :slug_en
      def self.name
        "Journalist"
      end
    end
    transaction do
      instance = model_class.create! :name => "hello", :slug_en => "hello"
      instance2 = model_class.create :name => "hello", :slug_en => "hello"
      assert instance.valid?
      refute instance2.valid?
    end
  end
end

class SlugGeneratorTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  def model_class
    Journalist
  end

  test "should quote column names" do
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      self.table_name = "journalists"
      extend FriendlyId
      friendly_id :name, :use => :slugged, :slug_column => "strange name"
    end

    begin
      with_instance_of(model_class) {|record| assert model_class.find(record.friendly_id)}
    rescue ActiveRecord::StatementInvalid
      flunk "column name was not quoted"
    end
  end

  test "should not resequence lower sequences on update" do
    transaction do
      m1 = model_class.create! :name => "a b c d"
      assert_equal "a-b-c-d", m1.slug
      model_class.create! :name => "a b c d"
      m1 = model_class.find(m1.id)
      m1.save!
      assert_equal "a-b-c-d", m1.slug
    end
  end

  test "should correctly sequence slugs that end with numbers" do
    transaction do
      record1 = model_class.create! :name => "Peugeuot 206"
      assert_equal "peugeuot-206", record1.slug
      record2 = model_class.create! :name => "Peugeuot 206"
      assert_equal "peugeuot-206--2", record2.slug
    end
  end

  test "should correctly sequence slugs with underscores" do
    transaction do
      record1 = Novelist.create! :name => 'wordsfail, buildings tumble'
      record2 = Novelist.create! :name => 'word fail'
      assert_equal 'word_fail', record2.slug
    end
  end

  test "should correctly sequence slugs that start with numbers" do
    record1 = model_class.create! :name => '24-hour-testing'
    assert_equal '24-hour-testing', record1.slug
    record2 = model_class.create! :name => '24-hour-testing'
    assert_equal '24-hour-testing--2', record2.slug
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

  test "should correctly sequence slugs that uses single dashes as sequence separator" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "journalists"
      extend FriendlyId
      friendly_id :name, :use => :slugged, :sequence_separator => '-'
      def self.name
        "Journalist"
      end
    end
    transaction do
      record1 = model_class.create! :name => "Peugeuot 206"
      assert_equal "peugeuot-206", record1.slug
      record2 = model_class.create! :name => "Peugeuot 206"
      assert_equal "peugeuot-206-2", record2.slug
    end
  end

  test "should detect when a sequenced slug has changed when name ends in number and using single dash" do
    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "journalists"
      extend FriendlyId
      friendly_id :name, :use => :slugged, :sequence_separator => '-'
    end
    transaction do
      record1 = model_class.create! :name => "Peugeuot 206"
      assert !record1.should_generate_new_friendly_id?
      record1.save!
      assert !record1.should_generate_new_friendly_id?
      record1.name = "Peugeot 307"
      assert record1.should_generate_new_friendly_id?
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

class UnderscoreAsSequenceSeparatorRegressionTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  class Manual < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged, :sequence_separator => "_"
  end

  test "should not create duplicate slugs" do
    3.times do
      begin
        assert Manual.create! :name => "foo"
      rescue
        flunk "Tried to insert duplicate slug"
      end
    end
  end

end

# https://github.com/norman/friendly_id/issues/148
class FailedValidationAfterUpdateRegressionTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
    validates_presence_of :slug_de
  end

  test "to_param should return the unchanged value if the slug changes before validation fails" do
    transaction do
      journalist = Journalist.create! :name => "Joseph Pulitzer", :slug_de => "value"
      assert_equal "joseph-pulitzer", journalist.to_param
      assert journalist.valid?
      assert journalist.persisted?
      journalist.name = "Joe Pulitzer"
      journalist.slug_de = nil
      assert !journalist.valid?
      assert_equal "joseph-pulitzer", journalist.to_param
    end
  end
end
