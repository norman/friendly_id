require File.expand_path("../test/helper", __FILE__)
require "ffaker"
require "friendly_id/migration"

N = 1000

migration do |m|
  m.add_column :users, :slug, :string
  m.add_index  :users, :slug, :unique => true
end

migration do |m|
  m.create_table :posts do |t|
    t.string :name
    t.string :slug
  end
  m.add_index  :posts, :slug, :unique => true
end
CreateFriendlyIdSlugs.up


class Array
  def rand
    self[Kernel.rand(length)]
  end
end

class User
  include FriendlyId::Slugged
  has_friendly_id :name
end

class Post < ActiveRecord::Base
  include FriendlyId::History
  has_friendly_id :name
end

USERS = []
BOOKS = []
POSTS = []

100.times do
  name = Faker::Name.name
  USERS << (User.create! :name => name).friendly_id
  POSTS << (Post.create! :name => name).friendly_id
  BOOKS << (Book.create! :name => name).id
end

Benchmark.bmbm do |x|
  x.report 'find (without FriendlyId)' do
    N.times {Book.find BOOKS.rand}
  end
  x.report 'find (in-table slug)' do
    N.times {User.find USERS.rand}
  end
  x.report 'find (external slug)' do
    N.times {Post.find_by_friendly_id POSTS.rand}
  end

  x.report 'insert (without FriendlyId)' do
    N.times {transaction {Book.create :name => Faker::Name.name}}
  end

  x.report 'insert (in-table-slug)' do
    N.times {transaction {User.create :name => Faker::Name.name}}
  end

  x.report 'insert (external slug)' do
    N.times {transaction {Post.create :name => Faker::Name.name}}
  end
end