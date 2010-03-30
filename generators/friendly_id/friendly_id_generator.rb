class FriendlyIdGenerator < Rails::Generator::Base

  RAKE_TASKS = File.join("..", "..", "..", "lib", "tasks", "friendly_id.rake")

  def manifest
    record do |m|
      unless options[:skip_migration]
        m.migration_template('create_slugs.rb', 'db/migrate', :migration_file_name => 'create_slugs')
      end
      unless options[:skip_tasks]
        m.directory "lib/tasks"
        m.file RAKE_TASKS, "lib/tasks/friendly_id.rake"
      end
    end
  end

  protected

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--skip-migration", "Don't generate a migration for the slugs table") do |value|
      options[:skip_migration] = value
    end
    opt.on("--skip-tasks", "Don't add friendly_id Rake tasks to lib/tasks") do |value|
      options[:skip_tasks] = value
    end
  end

end
