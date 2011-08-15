require "rubygems"
require "rake/testtask"

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :clean do
  %x{rm -rf *.gem doc pkg coverage}
  %x{rm -f `find . -name '*.rbc'`}
end

task :gem do
  %x{gem build friendly_id.gemspec}
end

task :yard do
  puts %x{bundle exec yard}
end

task :bench do
  require File.expand_path("../bench", __FILE__)
end

namespace :test do

  desc "Run each test class in a separate process"
  task :isolated do
    dir = File.expand_path("../test", __FILE__)
    Dir["#{dir}/*_test.rb"].each do |test|
      puts "Running #{test}:"
      puts %x{ruby #{test}}
    end
  end
end

namespace :db do

  desc "Create the database"
  task :create do
    require File.expand_path("../test/helper", __FILE__)
    driver = FriendlyId::Test::Database.driver
    config = FriendlyId::Test::Database.config[driver]
    commands = {
      "mysql"    => "mysql -e 'create database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'create database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
  end

  desc "Create the database"
  task :drop do
    require File.expand_path("../test/helper", __FILE__)
    driver = FriendlyId::Test::Database.driver
    config = FriendlyId::Test::Database.config[driver]
    commands = {
      "mysql"    => "mysql -e 'drop database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'drop database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
  end

  desc "Set up the database schema"
  task :up do
    require File.expand_path("../test/helper", __FILE__)
    FriendlyId::Test::Schema.up
  end

  desc "Drop and recreate the database schema"
  task :reset => [:drop, :create]

end

task :doc => :yard
