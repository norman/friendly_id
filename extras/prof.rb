#!/usr/bin/env ruby -KU
require File.dirname(__FILE__) + '/extras'
require 'ruby-prof'

# RubyProf.measure_mode = RubyProf::MEMORY
GC.disable
RubyProf.start
100.times do
  Post.find(slug = POSTS.rand)
end
result = RubyProf.stop
GC.enable
printer = RubyProf::CallTreePrinter.new(result)
printer.print(File.new("prof.txt", "w"))