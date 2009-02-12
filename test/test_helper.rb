$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))
$VERBOSE=false
require 'rubygems'
require 'test/unit'
require 'shoulda'
# You can use "rake test AR_VERSION=2.0.5" to test against 2.0.5, for example.
# The default is to use the latest installed ActiveRecord.
if ENV["AR_VERSION"]
  gem 'activerecord', "#{ENV["AR_VERSION"]}"
end
require 'active_record'

require 'friendly_id'
require 'models/post'
require 'models/person'
require 'models/user'
require 'models/country'
require 'models/book'
require 'models/novel'
require 'models/thing'

# Borrowed from ActiveSupport
def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
end

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
silence_stream(STDOUT) do
  load(File.dirname(__FILE__) + "/schema.rb")
end