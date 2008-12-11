require 'rubygems'
require 'active_support'
require 'hoe'
require File.join(File.dirname(__FILE__), 'lib', 'friendly_id', 'version')

Hoe.new("friendly_id", FriendlyId::Version::STRING) do |p|
  p.rubyforge_name = "friendly-id"
  p.author = ['Norman Clarke', 'Adrian Mugnolo', 'Emilio Tagua']
  p.email = ['norman@randomba.org', 'adrian@randomba.org', 'miloops@gmail.com']
  p.summary = "A comprehensive slugging and pretty-URL plugin for Ruby on Rails."
  p.description = 'A comprehensive slugging and pretty-URL plugin for Ruby on Rails.'
  p.url = 'http://randomba.org'
  p.need_tar = true
  p.need_zip = true
  p.test_globs = ['test/**/*_test.rb']
  p.extra_deps << ['unicode', '>= 0.1']
  p.rdoc_pattern = '*.rdoc'
end