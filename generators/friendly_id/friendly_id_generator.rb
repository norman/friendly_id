class FriendlyIdGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      unless options[:skip_migration]
        m.migration_template(
          'create_slugs.rb', 'db/migrate', :migration_file_name => 'create_slugs'
        )
        m.directory "lib/tasks"
        m.file "/../../../lib/tasks/friendly_id.rake", "lib/tasks/friendly_id.rake"
      end
    end
  end
end
