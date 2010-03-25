$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false
begin
  require File.join(File.dirname(__FILE__), '../.bundle/environment')
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end
require "test/unit"
require "mocha"
require "active_support"
require File.dirname(__FILE__) + "/../lib/friendly_id"
require File.dirname(__FILE__) + "/../lib/friendly_id/test"
