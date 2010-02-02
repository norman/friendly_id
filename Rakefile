require "rake"
require "rake/testtask"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rake/clean"

CLEAN << "pkg" << "doc" << "coverage" << ".yardoc"

Rake::GemPackageTask.new(eval(File.read("friendly_id.gemspec"))) { |pkg| }
Rake::RDocTask.new do |r|
  r.rdoc_dir = "doc"
  r.rdoc_files.include "lib/**/*.rb"
end

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

task :test do
  puts "\nTesting FriendlyId:\n\n"
  Rake::Task["test:friendly_id"].invoke
  puts "\nTesting ActiveRecord 2:\n\n"
  Rake::Task["test:ar2"].invoke
  puts "\nTesting Sequel:\n\n"
  Rake::Task["test:sequel"].invoke
end

namespace :test do

  task :rails do
    rm_rf "fid"
    sh "rails --template extras/template-gem.rb fid"
    sh "cd fid; rake test"
  end

  Rake::TestTask.new(:friendly_id) { |t| t.pattern = "test/*_test.rb" }
  Rake::TestTask.new(:ar2) { |t| t.pattern = "test/active_record2/*_test.rb" }
  Rake::TestTask.new(:sequel) { |t| t.pattern = "test/sequel/*_test.rb" }

end

task :pushdocs do
  branch = `git branch | grep "*"`.chomp.gsub("* ", "")
  sh "git stash"
  sh "git checkout gh-pages"
  sh "cp -rp doc/* ."
  sh 'git commit -a -m "Regenerated docs"'
  sh "git push origin gh-pages"
  sh "git checkout #{branch}"
  sh "git stash apply"
end