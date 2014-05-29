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

  test 'should allow a record to reuse its own slug' do
    with_instance_of(model_class) do |record|
      old_id = record.friendly_id
      record.slug = nil
      record.save!
      assert_equal old_id, record.friendly_id
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
      # This has been added in 635731bb to fix MySQL/Rubinius. It may still
      # be necessary, but causes an exception to be raised on Rails 4, so I'm
      # commenting it out. If it causes MySQL/Rubinius to fail again we'll
      # look for another solution.
      # self.abstract_class = true
      self.table_name = "journalists"
      extend FriendlyId
      friendly_id :name, :use => :slugged, :slug_column => "strange name"
    end

    begin
      with_instance_of(model_class) {|record| assert model_class.friendly.find(record.friendly_id)}
    rescue ActiveRecord::StatementInvalid
      flunk "column name was not quoted"
    end
  end

  test "should not resequence lower sequences on update" do
    transaction do
      m1 = model_class.create! :name => "a b c d"
      assert_equal "a-b-c-d", m1.slug
      model_class.create! :name => "a b c d"
      m1 = model_class.friendly.find(m1.id)
      m1.save!
      assert_equal "a-b-c-d", m1.slug
    end
  end

  test "should correctly sequence slugs that end with numbers" do
    transaction do
      record1 = model_class.create! :name => "Peugeot 206"
      assert_equal "peugeot-206", record1.slug
      record2 = model_class.create! :name => "Peugeot 206"
      assert_match(/\Apeugeot-206-([a-z0-9]+\-){4}[a-z0-9]+\z/, record2.slug)
    end
  end

  test "should correctly sequence slugs with underscores" do
    transaction do
      Novelist.create! :name => 'wordsfail, buildings tumble'
      record2 = Novelist.create! :name => 'word fail'
      assert_equal 'word_fail', record2.slug
    end
  end

  test "should correctly sequence numeric slugs" do
    transaction do
      n2 = 2.times.map {Article.create :name => '123'}.last
      assert_match(/\A123-.*/, n2.friendly_id)
    end
  end

  test "should not allow duplicate slugs after regeneration for persisted record" do
    transaction do
      model1 = model_class.create! :name => "a"
      model2 = model_class.new :name => "a"
      model2.save!

      model2.send(:set_slug)
      first_generated_friendly_id = model2.friendly_id
      model2.send(:set_slug)
      second_generated_friendly_id = model2.friendly_id

      assert model1.friendly_id != model2.friendly_id
    end
  end

  test "should not allow duplicate slugs after regeneration for new record" do
    transaction do
      model1 = model_class.create! :name => "a"
      model2 = model_class.new :name => "a"

      model2.send(:set_slug)
      first_generated_friendly_id = model2.friendly_id
      model2.send(:set_slug)
      second_generated_friendly_id = model2.friendly_id

      assert model1.friendly_id != model2.friendly_id
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

  test "should sequence with configured sequence separator" do
    with_instance_of model_class do |record|
      record2 = model_class.create! :name => record.name
      assert record2.friendly_id.match(/:.*\z/)
    end
  end

  test "should detect when a stored slug has been cleared" do
    with_instance_of model_class do |record|
      record.slug = nil
      assert record.should_generate_new_friendly_id?
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
      record1 = model_class.create! :name => "Peugeot 206"
      assert_equal "peugeot-206", record1.slug
      record2 = model_class.create! :name => "Peugeot 206"
      assert_match(/\Apeugeot-206-([a-z0-9]+\-){4}[a-z0-9]+\z/, record2.slug)
    end
  end
end

class DefaultScopeTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
    default_scope -> { where(:active => true).order('id ASC') }
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

class UuidAsPrimaryKeyFindTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  class MenuItem < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
    before_create :init_primary_key

    def self.primary_key
      "uuid_key"
    end

    # Overwrite the method added by FriendlyId
    def self.primary_key_type
      :uuid
    end

    private
    def init_primary_key
      self.uuid_key = SecureRandom.uuid
    end
  end

  def model_class
    MenuItem
  end

  test "should have a uuid_key as a primary key" do
    assert_equal model_class.primary_key, "uuid_key"
    assert_equal model_class.columns.find(&:primary).name, "uuid_key"
    assert_equal model_class.primary_key_type, :uuid
  end

  test "should be findable by the UUID primary key" do
    with_instance_of(model_class) do |record|
      assert model_class.friendly.find record.id
    end
  end

  test "should handle a string that simply contains a UUID correctly" do
    with_instance_of(model_class) do |record|
      assert_raises(ActiveRecord::RecordNotFound) do
        model_class.friendly.find "test-#{SecureRandom.uuid}"
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
