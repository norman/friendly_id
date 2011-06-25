require "cutest"

task :default => :test
task :test do
  Cutest.run(Dir["test/*_test.rb"])
end

task :clean do
  %x{rm -rf *.gem doc}
end

task :gem do
  %x{gem build friendly_id.gemspec}
end

task :yard do
  %x{yard doc}
end

task :doc => :yard
