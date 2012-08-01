require "helper"

class Book < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name
end

class Author < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name
  has_many :books
end

class CoreTest < MiniTest::Unit::TestCase

  include FriendlyId::Test
  include FriendlyId::Test::Shared::Core

  def model_class
    Author
  end

  test "models don't use friendly_id by default" do
    assert !Class.new(ActiveRecord::Base) {
      self.abstract_class = true
    }.respond_to?(:friendly_id)
  end

  test "model classes should have a friendly id config" do
    assert model_class.friendly_id(:name).friendly_id_config
  end

  test "instances should have a friendly id" do
    with_instance_of(model_class) {|record| assert record.friendly_id}
  end

  test "instances can be marshaled when a relationship is used" do
    transaction do
      author = Author.create :name => 'Philip'
      author.books.create :name => 'my book'
      begin
        assert Marshal.load(Marshal.dump(author))
      rescue TypeError => e
        flunk(e.to_s)
      end
    end
  end
end
