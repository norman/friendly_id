$:.unshift File.expand_path("../lib", File.dirname(__FILE__))
$:.unshift File.expand_path(File.dirname(__FILE__))
$:.uniq!

require "extras"
require 'ruby-prof'

# RubyProf.measure_mode = RubyProf::MEMORY
GC.disable
RubyProf.start
100.times do
  Post.find(slug = POSTS.rand)
end
result = RubyProf.stop
GC.enable
# printer = RubyProf::CallTreePrinter.new(result)
printer = RubyProf::GraphPrinter.new(result)
version = ActiveRecord::VERSION::STRING.gsub(".", "")
printer.print(File.new("prof#{version}.txt", "w"))