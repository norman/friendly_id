require File.expand_path("../../../helper", __FILE__)

require "ancestry"

ActiveRecord::Migration.create_table("things") do |t|
  t.string  :name
  t.string  :slug
  t.string :ancestry
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
    3.times.inject([]) do |memo, _|
      memo << Thing.create!(:name => "a", :parent => memo.last)
    end.each do |thing|
      assert_equal "a", thing.friendly_id
    end
  end
end

