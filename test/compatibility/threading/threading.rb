ENV["DB"] = "postgres"

require "thread"
require File.expand_path("../../../helper", __FILE__)

ActiveRecord::Migration.tap do |m|
  m.drop_table "things"
  m.create_table("things") do |t|
    t.string  :name
    t.string  :slug
  end
  m.add_index :things, :slug, :unique => true
end

class Thing < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged
end

$things = 10.times.map do
  Thing.new :name => "a b c"
end

$mutex = Mutex.new

def save_thing
  thing = $mutex.synchronize do
    $things.pop
  end
  if thing.nil? then return end
  Thing.transaction do
    Thing.connection.execute "LOCK TABLE things"
    thing.save!
    print "#{thing.friendly_id}\n"
  end
  true
end

2.times.map do
  Thread.new do
    while true do
      break unless save_thing
    end
  end
end.map(&:value)