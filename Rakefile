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

task :yard => :guide do
  puts %x{bundle exec yard}
end

task :bench do
  require File.expand_path("../bench", __FILE__)
end

task :guide do
  def read_comments(path)
    path  = File.expand_path("../#{path}", __FILE__)
    match = File.read(path).match(/\n=begin(.*)\n=end/m)[1].to_s
    match.split("\n").reject {|x| x =~ /^@/}.join("\n")
  end

  buffer = []

  buffer << read_comments("lib/friendly_id.rb")
  buffer << read_comments("lib/friendly_id/base.rb")
  buffer << read_comments("lib/friendly_id/slugged.rb")
  buffer << read_comments("lib/friendly_id/history.rb")
  buffer << read_comments("lib/friendly_id/scoped.rb")
  buffer << read_comments("lib/friendly_id/simple_i18n.rb")
  buffer << read_comments("lib/friendly_id/reserved.rb")

  File.open("Guide.rdoc", "w") do |file|
    file.write("#encoding: utf-8\n")
    file.write(buffer.join("\n"))
  end
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
