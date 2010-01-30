namespace :friendly_id do
  desc "Make slugs for a model."
  task :make_slugs => :environment do
    FriendlyId::TaskRunner.new.make_slugs do |record|
      puts "%s(%d): friendly_id set to '%s'" % [record.class.to_s, record.id, record.slug.name]
    end
  end

  desc "Regenereate slugs for a model."
  task :redo_slugs => :environment do
    FriendlyId::TaskRunner.new.delete_slugs
    Rake::Task["friendly_id:make_slugs"].invoke
  end

  desc "Kill obsolete slugs older than DAYS=45 days."
  task :remove_old_slugs => :environment do
    FriendlyId::TaskRunner.new.delete_old_slugs
  end
end