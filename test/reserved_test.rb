require File.expand_path("../helper.rb", __FILE__)

class ReservedTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name
  end


  def model_class
    Journalist
  end

  test "should reserve 'new' and 'edit' by default" do
    ["new", "edit"].each do |word|
      transaction do
        assert_raises(ActiveRecord::RecordInvalid) {model_class.create! :name => word}
      end
    end
  end
end


