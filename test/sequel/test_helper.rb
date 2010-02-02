require File.dirname(__FILE__) + "/../test_helper"
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel.rb"
require File.dirname(__FILE__) + "/core"

DB = Sequel.sqlite

DB.create_table(:users) do
  primary_key :id, :type => Integer
  string :name, :unique => true
  string :note
end

DB.create_table(:posts) do
  primary_key :id, :type => Integer
  string :name, :unique => true
  string :note
end

class User < Sequel::Model
end

class Post < Sequel::Model
end

User.plugin :friendly_id, :name
Post.plugin :friendly_id, :name