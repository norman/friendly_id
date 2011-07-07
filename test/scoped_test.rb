# # encoding: utf-8
# require File.expand_path("../helper", __FILE__)
# 
# migration do |m|
#   m.add_column :books, :slug, :string
#   m.add_column :books, :user_id, :integer
# end
# 
# User.has_many :books
# Book.belongs_to :user
# Book.send :include, FriendlyId::Scoped
# Book.has_friendly_id :name, :scope => :user
# 
# test "should detect scope column from belongs_to relation" do
#   assert_equal "user_id", Book.friendly_id_config.scope_column
# end
# 
# test "should detect scope column from explicit column name" do
#   klass = Class.new(ActiveRecord::Base)
#   klass.has_friendly_id :empty, :scope => :dummy
#   assert_equal "dummy", klass.friendly_id_config.scope_column
# end
# 
# test "should allow duplicate slugs outside scope" do
#   transaction do
#     book1 = Book.create! :name => "a", :user => User.create!(:name => "a")
#     book2 = Book.create! :name => "a", :user => User.create!(:name => "b")
#     assert_equal book1.friendly_id, book2.friendly_id
#   end
# end
# 
# test "should not allow duplicate slugs inside scope" do
#   with_instance_of User do |user|
#     book1 = Book.create! :name => "a", :user => user
#     book2 = Book.create! :name => "a", :user => user
#     assert book1.friendly_id != book2.friendly_id
#   end
# end
# 
# setup { Book }
# 
# require File.expand_path("../shared.rb", __FILE__)