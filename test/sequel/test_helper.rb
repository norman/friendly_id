require "rubygems"
require "sequel/extensions/migration"
require File.dirname(__FILE__) + "/../test_helper"
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel"
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel/create_slugs"
require File.dirname(__FILE__) + "/core"

DB = Sequel.sqlite
FriendlyId::Sequel::CreateSlugs.apply(DB, :up)
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel/slug"

%w[books posts users].each do |table|
  DB.create_table(table) do
    primary_key :id, :type => Integer
    string :name, :unique => true
    string :note
  end
end

class User < Sequel::Model; end
class Book < Sequel::Model; end
class Post < Sequel::Model; end

User.plugin :friendly_id, :name
Book.plugin :friendly_id, :name
Post.plugin :friendly_id, :name, :use_slug => true