class FriendlyIdMigrationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      unless options[:skip_migration]
        m.migration_template(
          'create_slugs.rb', 'db/migrate', :migration_file_name => 'create_slugs'
        )
      end
    end
  end
end