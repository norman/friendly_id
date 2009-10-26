require "friendly_id/tasks"

namespace :friendly_id do
  desc "Make slugs for a model."
  task :make_slugs => :environment do
    validate_model_given
    FriendlyId::Tasks.make_slugs(ENV["MODEL"]) do |r|
      puts "%s(%d) friendly_id set to '%s'" % [r.class.to_s, r.id, r.slug.name]
    end
  end

  desc "Regenereate slugs for a model."
  task :redo_slugs => :environment do
    validate_model_given
    FriendlyId::Tasks.delete_slugs_for(ENV["MODEL"])
    Rake::Task["friendly_id:make_slugs"].invoke
  end

  desc "Kill obsolete slugs older than DAYS=45 days."
  task :remove_old_slugs => :environment do
    FriendlyId::Task.delete_old_slugs(ENV["DAYS"], ENV["MODEL"])
  end
end

def validate_model_given
  raise 'USAGE: rake friendly_id:make_slugs MODEL=MyModelName' if ENV["MODEL"].nil?
end
