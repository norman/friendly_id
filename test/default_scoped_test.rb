require File.expand_path("../helper.rb", __FILE__)

class DefaultScopeTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  class OrderedJournalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :slugged
    default_scope :order => 'position ASC'
  end
  
  test "friendly_id should sequence correctly a default_scoped ordered table" do
    OrderedJournalist.create!({ :name => 'I\'m unique', :position => 1 })
    OrderedJournalist.create!({ :name => 'I\'m unique', :position => 2 })
    OrderedJournalist.create!({ :name => 'I\'m unique', :position => 3 }) # should not raise SQLite3::ConstraintException: column slug is not unique: INSERT INTO "ordered_journalists" ("name", "active", "slug", "position") VALUES ('I''m unique', NULL, 'i-m-unique--2', 3)
  end
end