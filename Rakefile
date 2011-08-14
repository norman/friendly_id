require "rubygems"
require "rake/testtask"

def rubies(&block)
  ["ruby-1.9.2-p180", "ree-1.8.7-2011.03", "jruby-1.6.2", "rbx-2.0.0pre"].each do |ruby|
    old = ENV["RB"]
    ENV["RB"] = ruby
    yield
    ENV["RB"] = old
  end
end

def versions(&block)
  ["3.1.0.rc5", "3.0.9"].each do |version|
    old = ENV["AR"]
    ENV["AR"] = version
    yield
    ENV["AR"] = old
  end
end

def adapters(&block)
  ["mysql", "mysql2", "postgres", "sqlite3"].each do |adapter|
    old = ENV["DB"]
    ENV["DB"] = adapter
    ENV["DB_VERSION"] = "~> 0.3.6" if adapter == "mysql2" && ENV["AR"] && ENV["AR"][0..2] >= "3.1"
    yield
    ENV["DB"] = old
  end
end

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

desc "Bundle for all supported Ruby/AR versions"
task :bundle do
  rubies do
    versions do
      command = "#{ENV["RB"]} -S bundle"
      puts "#{command} (with #{ENV['AR']})"
      `#{command}`
    end
  end
end

namespace :test do

  desc "Test with all configured adapters"
  task :adapters do
    adapters {|a| puts %x{rake test}}
  end

  desc "Test with all configured Rubies"
  task :rubies do
    rubies {|r| puts %x{rake-#{ENV["RB"]} test}}
  end

  desc "Test with all configured versions"
  task :versions do
    versions {|v| puts %x{rake test}}
  end

  desc "Test all rubies, versions and adapters"
  task :prerelease do
    rubies do
      versions do
        adapters do
          puts %x{rake test}
        end
      end
    end
  end

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

  desc "Set up the"
  task :reset => [:drop, :create]

end

task :doc => :yard
