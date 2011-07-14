require File.expand_path("../helper.rb", __FILE__)

Author, Book = 2.times.map do
  Class.new(ActiveRecord::Base) do
    has_friendly_id :name
  end
end

class CoreTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared

  def klass
    Author
  end

  test "models don't use friendly_id by default" do
    assert !Class.new(ActiveRecord::Base).uses_friendly_id?
  end

  test "model classes should have a friendly id config" do
    assert klass.has_friendly_id(:name).friendly_id_config
  end

  test "should raise error when bad config options are set" do
    assert_raises ArgumentError do
      klass.has_friendly_id :name, :garbage => :in
    end
  end

  test "should reserve 'new' and 'edit' by default" do
    ["new", "edit"].each do |word|
      transaction do
        assert_raises(ActiveRecord::RecordInvalid) {klass.create! :name => word}
      end
    end
  end

  test "instances should have a friendly id" do
    with_instance_of(klass) {|record| assert record.friendly_id}
  end
end
