require File.expand_path("../../helper", __FILE__)

require "ancestry"

ActiveRecord::Migration.create_table("things") do |t|
  t.string  :name
  t.string  :slug
  t.integer :ancestry
end
ActiveRecord::Migration.add_index :things, :ancestry

class Thing < ActiveRecord::Base
  extend FriendlyId
  friendly_id do |config|
    config.use :slugged
    config.use :scoped
    config.base  = :name
    config.scope = :ancestry
  end
  has_ancestry
end

class AncestryTest < MiniTest::Unit::TestCase

  include FriendlyId::Test

  test "should sequence slugs when scoped by ancestry" do
    thing1 = Thing.create! :name => "a"
    thing2 = Thing.create! :name => "b", :parent => thing1
    thing3 = Thing.create! :name => "b", :parent => thing2

    assert_equal "a", thing1.slug
    assert_equal "a--2", thing2.slug
    assert_equal "a--3", thing3.slug
  end
end

