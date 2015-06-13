require File.expand_path("../../helper", __FILE__)
require "ffaker"

# This benchmark tests ActiveRecord and FriendlyId methods for performing a find
#
# ActiveRecord: where.first                     8.970000   0.040000   9.010000 (  9.029544)
# ActiveRecord: where.take                      8.100000   0.030000   8.130000 (  8.157024)
# ActiveRecord: find                            2.720000   0.010000   2.730000 (  2.733527)
# ActiveRecord: find_by(:id)                    2.920000   0.000000   2.920000 (  2.926318)
# ActiveRecord: find_by(:slug)                  2.650000   0.020000   2.670000 (  2.662677)
# FriendlyId: find (in-table slug w/ finders)   9.820000   0.030000   9.850000 (  9.873358)
# FriendlyId: friendly.find (in-table slug)    12.890000   0.050000  12.940000 ( 12.951156)

N = 50000

class Array
  def rand
    self[Kernel.rand(length)]
  end
end

Book = Class.new ActiveRecord::Base

class Restaurant < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :finders
end

class UnfriendlyRestaurant < ActiveRecord::Base
  self.table_name = 'restaurants'
end

BOOKS       = []
RESTAURANTS = []

100.times do
  name = FFaker::Name.name
  BOOKS       << (Book.create! :name => name).id
  RESTAURANTS << (Restaurant.create! :name => name).friendly_id
end
RESTAURANT_IDS = Restaurant.ids
RESTAURANT_ID_STRINGS = Restaurant.ids.map(&:to_s)

puts 'Comparing .find() with and without Finders and using integer ids, string ids, and string slugs'
Benchmark.bmbm do |x|

  x.report 'Unfriendly: find(id integer)' do
    N.times {UnfriendlyRestaurant.find RESTAURANT_IDS.rand}
  end

  x.report 'FriendlyFinder: find(id integer)' do
    N.times {Restaurant.find RESTAURANT_IDS.rand}
  end

  x.report 'Unfriendly: find(id string)' do
    N.times {UnfriendlyRestaurant.find RESTAURANT_ID_STRINGS.rand}
  end

  x.report 'FriendlyFinder: find(id string)' do
    N.times {Restaurant.find RESTAURANT_ID_STRINGS.rand}
  end

  x.report 'FriendlyFinder: find(slug string)' do
    N.times {Restaurant.find RESTAURANTS.rand}
  end

end

puts 'Comparing ActiveRecord query approaches'
Benchmark.bmbm do |x|
  x.report 'ActiveRecord: where.first' do
    N.times {Book.where(:id=>BOOKS.rand).first}
  end

  x.report 'ActiveRecord: where.take' do
    N.times {Book.where(:id=>BOOKS.rand).take}
  end

  x.report 'ActiveRecord: find' do
    N.times {Book.find BOOKS.rand}
  end

  x.report 'ActiveRecord: find_by(:id)' do
    N.times {Book.find_by(:id=>BOOKS.rand)}
  end

  x.report 'ActiveRecord: find_by(:slug)' do
    N.times {Restaurant.find_by(:slug=>RESTAURANTS.rand)}
  end

  x.report 'FriendlyId: find (in-table slug w/ finders)' do
    N.times {Restaurant.find RESTAURANTS.rand}
  end

  x.report 'FriendlyId: friendly.find (in-table slug)' do
    N.times {Restaurant.friendly.find RESTAURANTS.rand}
  end

end
