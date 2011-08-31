require File.expand_path("../../../helper", __FILE__)

ActiveRecord::Migration.create_table("users") do |t|
  t.string  :name
  t.string  :type
end

ActiveRecord::Migration.create_table("productions") do |t|
  t.string  :name
  t.string  :slug
end

class AbstractUser < ActiveRecord::Base
  set_table_name "users"
end

class User < AbstractUser
end

class Org < AbstractUser
end

class Production < ActiveRecord::Base
  extend FriendlyId
  belongs_to :user, :class_name => "AbstractUser", :foreign_key => :user_id
  friendly_id :name, :use => :scoped, :scope => :user
end

class ScopesAndStiTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  test "should detect scope column from belongs_to relation" do
    assert_equal "user_id", Production.friendly_id_config.scope_column
  end
end
