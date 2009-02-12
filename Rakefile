require 'newgem'
require 'lib/friendly_id/version'

$hoe = Hoe.new("friendly_id", FriendlyId::Version::STRING) do |p|
  p.rubyforge_name = "friendly-id"
  p.author = ['Norman Clarke', 'Adrian Mugnolo', 'Emilio Tagua']
  p.email = ['norman@randomba.org', 'adrian@randomba.org', 'miloops@gmail.com']
  p.summary = "A comprehensive slugging and pretty-URL plugin for ActiveRecord."
  p.description = 'A comprehensive slugging and pretty-URL plugin for ActiveRecord.'
  p.url = 'http://friendly-id.rubyforge.org/'
  p.test_globs = ['test/**/*_test.rb']
  p.extra_deps << ['unicode', '>= 0.1']
  p.extra_deps << ['activerecord', '>= 2.0.0']
  p.extra_dev_deps << ['newgem', ">= #{::Newgem::VERSION}"]
  p.extra_dev_deps << ['Shoulda', ">= 1.2.0"]
  p.extra_dev_deps << ['sqlite3-ruby']
  p.remote_rdoc_dir = ""
end

require 'newgem/tasks'

desc "Run RCov"
task :rcov do
  run_coverage Dir["test/**/*_test.rb"]
end

def run_coverage(files)
  rm_f "coverage"
  rm_f "coverage.data"
  if files.length == 0
    puts "No files were specified for testing"
    return
  end
  files = files.join(" ")
  if PLATFORM =~ /darwin/
    exclude = '--exclude "gems/"'
  else
    exclude = '--exclude "rubygems"'
  end
  rcov = "rcov -Ilib:test --sort coverage --text-report #{exclude} --no-validator-links"
  cmd = "#{rcov} #{files}"
  puts cmd
  sh cmd
end

desc 'Publish RDoc to RubyForge.'
task :publish_docs => [:clean, :docs] do
  host = "compay@rubyforge.org"
  remote_dir = "/var/www/gforge-projects/friendly-id"
  local_dir = 'doc'
  sh %{rsync -av --delete #{local_dir}/ #{host}:#{remote_dir}}
end