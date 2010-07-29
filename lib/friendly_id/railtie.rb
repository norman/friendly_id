module FriendlyId
  class Railtie < Rails::Railtie

    initializer "friendly_id.configure_rails_initialization" do |app|
      # Experimental Sequel support. See: http://github.com/norman/friendly_id_sequel
      if app.config.generators.rails[:orm] == :sequel
        require "friendly_id/sequel"
      # Experimental DataMapper support. See: http://github.com/myabc/friendly_id_datamapper
      elsif app.config.generators.rails[:orm] == :data_mapper
        require 'friendly_id/datamapper'
      else
        # AR is the default.
        require "friendly_id/active_record"
      end
    end

    rake_tasks do
      load "tasks/friendly_id.rake"
    end

  end
end
