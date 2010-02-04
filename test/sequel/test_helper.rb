require "rubygems"
require "sequel/extensions/migration"
require "logger"

require File.dirname(__FILE__) + "/../test_helper"
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel"
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel/create_slugs"
require File.dirname(__FILE__) + "/../generic"
require File.dirname(__FILE__) + "/../slugged"
require File.dirname(__FILE__) + "/core"
require File.dirname(__FILE__) + "/simple"
require File.dirname(__FILE__) + "/slugged"

DB = Sequel.sqlite
FriendlyId::Sequel::CreateSlugs.apply(DB, :up)
require File.dirname(__FILE__) + "/../../lib/friendly_id/sequel/slug"

%w[books users].each do |table|
  DB.create_table(table) do
    primary_key :id, :type => Integer
    string :name, :unique => true
    string :note
  end
end

class Book < Sequel::Model; end
class User < Sequel::Model; end

Book.plugin :friendly_id, :name
User.plugin :friendly_id, :name

%w[animals cities people posts].each do |table|
  DB.create_table(table) do
    primary_key :id, :type => Integer
    string :name
    string :note
  end
end

class Animal < Sequel::Model; end
class Cat < Animal; end
class City < Sequel::Model; end
class Post < Sequel::Model; end
class Person < Sequel::Model
  def normalize_friendly_id(string)
    string.upcase
  end
end

[Cat, City, Post, Person].each do |klass|
  klass.plugin :friendly_id, :name, :use_slug => true
end

# DB.loggers << Logger.new($stdout)