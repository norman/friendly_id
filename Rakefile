require "rubygems"
require "bundler/gem_tasks"
require "rake/testtask"

task default: :test

task :load_path do
  %w[lib test].each do |path|
    $LOAD_PATH.unshift(File.expand_path("../#{path}", __FILE__))
  end
end

desc "Run the Active Record test suite"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/*_test.rb"]
  t.verbose = true
end

# Runs in its own process and with its own load path, because the point of the
# ROM adapter is that it works without Active Record and the Active Record suite
# loads it eagerly.
desc "Run the ROM adapter test suite"
Rake::TestTask.new(:test_rom) do |t|
  t.libs = ["lib", "test/rom"]
  t.test_files = FileList["test/rom/*_test.rb"]
  t.verbose = true
end

# Boots a real Hanami 3.0 app with FriendlyId mounted by path. Has its own
# bundle, so it runs as a subprocess rather than in this one.
desc "Run the Hanami application smoke tests"
task :test_hanami do
  dir = File.expand_path("test/hanami_app", __dir__)
  Bundler.with_unbundled_env do
    sh "cd #{dir} && bundle install --quiet && bundle exec ruby test/smoke_test.rb && bundle exec ruby test/generator_test.rb"
  end
end

desc "Run every test suite"
task test_all: [:test, :test_rom, :test_hanami]

desc "Remove temporary files"
task :clean do
  `rm -rf *.gem doc pkg coverage`
  %x(rm -f `find . -name '*.rbc'`)
end

desc "Build YARD documentation"
task :yard do
  puts `bundle exec yard`
end

desc "Run benchmarks"
task bench: :load_path do
  require File.expand_path("../bench", __FILE__)
end

desc "Run benchmarks on finders"
task bench_finders: :load_path do
  require File.expand_path("../test/benchmarks/finders", __FILE__)
end

desc "Run benchmarks on ObjectUtils"
task bench_object_utils: :load_path do
  require File.expand_path("../test/benchmarks/object_utils", __FILE__)
end

desc "Generate Guide.md"
task :guide do
  load File.expand_path("../guide.rb", __FILE__)
end

namespace :test do
  desc "Run each test class in a separate process"
  task :isolated do
    dir = File.expand_path("../test", __FILE__)
    Dir["#{dir}/*_test.rb"].each do |test|
      puts "Running #{test}:"
      puts `ruby -Ilib -Itest #{test}`
    end
  end
end

namespace :db do
  desc "Create the database"
  task create: :load_path do
    require "helper"
    driver = FriendlyId::Test::Database.driver
    config = FriendlyId::Test::Database.config[driver]
    commands = {
      "mysql" => "mysql -h #{config["host"]} -P #{config["port"]} -u #{config["username"]} --password=#{config["password"]} -e 'create database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'create database #{config["database"]};' -U #{config["username"]} >/dev/null"
    }
    `#{commands[driver] || true}`
  end

  desc "Drop the database"
  task drop: :load_path do
    require "helper"
    driver = FriendlyId::Test::Database.driver
    config = FriendlyId::Test::Database.config[driver]
    commands = {
      "mysql" => "mysql -h #{config["host"]} -P #{config["port"]} -u #{config["username"]} --password=#{config["password"]} -e 'drop database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'drop database #{config["database"]};' -U #{config["username"]} >/dev/null"
    }
    `#{commands[driver] || true}`
  end

  desc "Set up the database schema"
  task up: :load_path do
    require "helper"
    FriendlyId::Test::Schema.up
  end

  desc "Drop and recreate the database schema"
  task reset: [:drop, :create]
end

task doc: :yard

task :docs do
  sh %(git checkout gh-pages && rake doc && git checkout @{-1})
end
