require File.expand_path("../helper.rb", __FILE__)

Author, Book = 2.times.map do
  Class.new(ActiveRecord::Base) do
    extend FriendlyId
    friendly_id :name
  end
end

class CoreTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared

  def model_class
    Author
  end

  test "models don't use friendly_id by default" do
    assert !Class.new(ActiveRecord::Base).respond_to?(:friendly_id)
  end

  test "model classes should have a friendly id config" do
    assert model_class.friendly_id(:name).friendly_id_config
  end

  test "instances should have a friendly id" do
    with_instance_of(model_class) {|record| assert record.friendly_id}
  end
end
