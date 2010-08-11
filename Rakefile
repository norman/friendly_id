require "rake"
require "rake/testtask"
require "rake/gempackagetask"
require "rake/clean"

task :default => :test

CLEAN << "pkg" << "doc" << "coverage" << ".yardoc"
Rake::GemPackageTask.new(eval(File.read("friendly_id.gemspec"))) { |pkg| }

begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    t.options = ["--output-dir=doc"]
    t.options << "--files" << ["Guide.md", "Contributors.md", "Changelog.md"].join(",")
  end
rescue LoadError
end

begin
  require "rcov/rcovtask"
  Rcov::RcovTask.new do |r|
    r.test_files = FileList["test/**/*_test.rb"]
    r.verbose = true
    r.rcov_opts << "--exclude gems/*"
  end
rescue LoadError
end


Rake::TestTask.new(:test) { |t| t.pattern = "test/**/*_test.rb" }

namespace :test do
  task :rails do
    rm_rf "fid"
    sh "rails --template extras/template-gem.rb fid"
    sh "cd fid; rake test"
  end
  Rake::TestTask.new(:friendly_id) { |t| t.pattern = "test/*_test.rb" }
  Rake::TestTask.new(:ar) { |t| t.pattern = "test/active_record_adapter/*_test.rb" }

  namespace :rails do
    task :plugin do
      rm_rf "fid"
      sh "rails --template extras/template-plugin.rb fid"
      sh "cd fid; rake test"
    end
  end

end

task :pushdocs do
  branch = `git branch | grep "*"`.chomp.gsub("* ", "")
  sh "git checkout gh-pages"
  sh "rm -rf FriendlyId ActiveRecord css js *.html"
  sh "cp -rp doc/* ."
  sh 'git commit -a -m "Regenerated docs"'
  sh "git push origin gh-pages"
  sh "git checkout #{branch}"
end
