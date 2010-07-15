module FriendlyId
  class Railtie < Rails::Railtie

    initializer "friendly_id.configure_rails_initialization" do |app|
      # Experimental Sequel support. See: http://github.com/norman/friendly_id_sequel
      if app.config.generators.rails[:orm] == :sequel
        require "friendly_id/sequel"
      else
        # Only Sequel and ActiveRecord are currently supported; AR is the default.
        # Want Datamapper support? http://github.com/norman/friendly_id/issues#issue/24
        require "friendly_id/active_record"
      end
    end

    rake_tasks do
      load "tasks/friendly_id.rake"
    end

  end
end