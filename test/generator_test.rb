require File.expand_path("../helper", __FILE__)

require "test/unit"
require "rails/generators"
require "generators/friendly_id_generator"

class FriendlyIdGeneratorTest < Rails::Generators::TestCase

  tests FriendlyIdGenerator
  destination File.expand_path("../../tmp", __FILE__)

  setup :prepare_destination

  test "should generate a migration" do
    begin
      run_generator
      assert_migration "db/migrate/create_friendly_id_slugs"
    ensure
      FileUtils.rm_rf self.destination_root
    end
  end
end
