class FriendlyId20UpgradeGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      unless options[:skip_migration]
        m.migration_template(
          'upgrade_friendly_id_to_20.rb', 'db/migrate', :migration_file_name => 'upgrade_friendly_id_to_20'
        )
      end
    end
  end
end