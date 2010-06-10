$KCODE = "UTF8" if RUBY_VERSION < "1.9"
$VERBOSE = false
begin
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end
require "test/unit"
require "mocha"
require "active_support"
# require "ruby-debug"
require File.expand_path("../../lib/friendly_id", __FILE__)
require File.expand_path("../../lib/friendly_id/test", __FILE__)
