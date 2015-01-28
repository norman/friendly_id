require "bundler/setup"

if ENV['COVERALLS'] || ENV['COVERAGE']
  require 'simplecov'
  if ENV['COVERALLS']
    require 'coveralls'
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  end
  SimpleCov.start do
    add_filter 'test'
    add_filter 'friendly_id/migration'
  end
end

begin
  require 'minitest'
rescue LoadError
  require 'minitest/unit'
end

begin
  TestCaseClass = MiniTest::Test
rescue NameError
  TestCaseClass = MiniTest::Unit::TestCase
end

require "mocha/setup"
require "active_record"
require 'active_support/core_ext/time/conversions'

I18n.enforce_available_locales = false

require "friendly_id"

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

module FriendlyId
  module Test

    def self.included(base)
      if Minitest.respond_to?(:autorun)
        Minitest.autorun
      else
        require 'minitest/autorun'
      end
    rescue LoadError
    end

    def transaction
      ActiveRecord::Base.transaction { yield ; raise ActiveRecord::Rollback }
    end

    def with_instance_of(*args)
      model_class = args.shift
      args[0] ||= {:name => "a b c"}
      transaction { yield model_class.create!(*args) }
    end

    module Database
      extend self

      def connect
        version = ActiveRecord::VERSION::STRING
        driver  = FriendlyId::Test::Database.driver
        engine  = RUBY_ENGINE rescue "ruby"

        ActiveRecord::Base.establish_connection config[driver]
        message = "Using #{engine} #{RUBY_VERSION} AR #{version} with #{driver}"

        puts "-" * 72
        if in_memory?
          ActiveRecord::Migration.verbose = false
          Schema.migrate :up
          puts "#{message} (in-memory)"
        else
          puts message
        end
      end

      def config
        @config ||= YAML::load(File.open(File.expand_path("../databases.yml", __FILE__)))
      end

      def driver
        (ENV["DB"] or "sqlite3").downcase
      end

      def in_memory?
        config[driver]["database"] == ":memory:"
      end
    end
  end
end

class Module
  def test(name, &block)
    define_method("test_#{name.gsub(/[^a-z0-9']/i, "_")}".to_sym, &block)
  end
end

require "schema"
require "shared"
FriendlyId::Test::Database.connect
at_exit {ActiveRecord::Base.connection.disconnect!}
