# encoding: utf-8

$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))
$KCODE = 'UTF8' if RUBY_VERSION < '1.9'
$VERBOSE = false
require 'test/unit'
require 'contest'
# You can use "rake test AR_VERSION=2.0.5" to test against 2.0.5, for example.
# The default is to use the latest installed ActiveRecord.
if ENV["AR_VERSION"]
  gem 'activerecord', "#{ENV["AR_VERSION"]}"
  gem 'activesupport', "#{ENV["AR_VERSION"]}"
end
require 'active_record'
require 'active_support'
require 'friendly_id'
require 'models/post'
require 'models/person'
require 'models/user'
require 'models/country'
require 'models/book'
require 'models/novel'
require 'models/thing'
require 'models/event'

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
silence_stream(STDOUT) do
  load(File.dirname(__FILE__) + "/schema.rb")
end