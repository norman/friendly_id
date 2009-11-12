require 'newgem'
require 'hoe'
require 'lib/friendly_id/version'
require 'hoe'

Hoe.spec "friendly_id" do
  self.version = FriendlyId::Version::STRING
  self.rubyforge_name = "friendly-id"
  self.author = ['Norman Clarke', 'Adrian Mugnolo', 'Emilio Tagua']
  self.email = ['norman@njclarke.com', 'adrian@mugnolo.com', 'miloops@gmail.com']
  self.summary = "A comprehensive slugging and pretty-URL plugin for ActiveRecord."
  self.description = 'A comprehensive slugging and pretty-URL plugin for ActiveRecord.'
  self.url = 'http://friendly-id.rubyforge.org/'
  self.test_globs = ['test/**/*_test.rb']
  self.extra_deps << ['activerecord', '>= 2.2.3']
  self.extra_deps << ['activesupport', '>= 2.2.3']
  self.extra_dev_deps << ['newgem', ">= #{::Newgem::VERSION}"]
  self.extra_dev_deps << ['sqlite3-ruby']
  self.remote_rdoc_dir = ""
	self.readme_file = "README.rdoc"
  self.extra_rdoc_files = ["README.rdoc"]
end

require 'newgem/tasks'

desc 'Publish RDoc to RubyForge.'
task :publish_docs => [:clean, :docs] do
  host = "compay@rubyforge.org"
  remote_dir = "/var/www/gforge-projects/friendly-id"
  local_dir = 'doc'
  sh %{rsync -av --delete #{local_dir}/ #{host}:#{remote_dir}}
end
