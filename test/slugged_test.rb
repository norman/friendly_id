require File.expand_path("../helper.rb", __FILE__)

Journalist, Article = 2.times.map do
  Class.new(ActiveRecord::Base) do
    include FriendlyId::Slugged
    has_friendly_id :name
  end
end

class SluggedTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared

  def klass
    Journalist
  end

  test "configuration should have a sequence_separator" do
    assert !klass.friendly_id_config.sequence_separator.empty?
  end

  test "should make a new slug if the friendly_id method value has changed" do
    with_instance_of klass do |record|
      record.name = "Changed Value"
      record.save!
      assert_equal "changed-value", record.slug
    end
  end

  test "should increment the slug sequence for duplicate friendly ids" do
    with_instance_of klass do |record|
      record2 = klass.create! :name => record.name
      assert record2.friendly_id.match(/2\z/)
    end
  end

  test "should not add slug sequence on update after other conflicting slugs were added" do
    with_instance_of klass do |record|
      old = record.friendly_id
      record2 = klass.create! :name => record.name
      record.save!
      record.reload
      assert_equal old, record.to_param
    end
  end
end

class SlugSequencerTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  test "should quote column names" do
    klass            = Class.new(ActiveRecord::Base)
    klass.table_name = "journalists"
    klass.send :include, FriendlyId::Slugged
    klass.has_friendly_id :name, :slug_column => "strange name"
    begin
      with_instance_of(klass) {|record| assert klass.find(record.friendly_id)}
    rescue ActiveRecord::StatementInvalid
      flunk "column name was not quoted"
    end
  end
end

class SlugSeparatorTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    include FriendlyId::Slugged
    has_friendly_id :name, :sequence_separator => ":"
  end

  def klass
    Journalist
  end

  test "should increment sequence with configured sequence separator" do
    with_instance_of klass do |record|
      record2 = klass.create! :name => record.name
      assert record2.friendly_id.match(/:2\z/)
    end
  end

  test "should detect when a sequenced slug has changed" do
    with_instance_of klass do |record|
      record2 = klass.create! :name => record.name
      assert !record2.slug_sequencer.slug_changed?
      record2.name = "hello world"
      assert record2.slug_sequencer.slug_changed?
    end
  end
end

class SluggedRegressionsTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  def klass
    Journalist
  end

  test "should increment the slug sequence for duplicate friendly ids beyond 10" do
    with_instance_of klass do |record|
      (2..12).each do |i|
        r = klass.create! :name => record.name
        assert r.friendly_id.match(/#{i}\z/)
      end
    end
  end
end