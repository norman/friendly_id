require "rubygems"
require "bundler/setup"
require "rake"
require "rake/testtask"
require "rake/gempackagetask"
require "rake/clean"

task :default => :test

CLEAN << "pkg" << "doc" << "coverage" << ".yardoc"

gemspec = File.expand_path("../friendly_id.gemspec", __FILE__)
if File.exists? gemspec
  Rake::GemPackageTask.new(eval(File.read("friendly_id.gemspec"))) { |pkg| }
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


Rake::TestTask.new(:test) { |t| t.pattern = "test/**/*_test.rb" }

namespace :test do
  task :rails do
    rm_rf "fid"
    sh "rails --template extras/template-gem.rb fid"
    sh "cd fid; rake test"
  end
  Rake::TestTask.new(:friendly_id) { |t| t.pattern = "test/*_test.rb" }
  Rake::TestTask.new(:ar) { |t| t.pattern = "test/active_record_adapter/*_test.rb" }

  desc "Test against lots of versions"
  task :pre_release do
    ["ree-1.8.7-2010.02", "ruby-1.9.2-p136"].each do |ruby|
      ["sqlite3", "mysql", "postgres"].each do |driver|
        [2, 3].each do |ar_version|
          command = "rake-#{ruby} test AR=#{ar_version} DB=#{driver}"
          puts command
          puts `#{command}`
        end
      end
    end
  end

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
  sh "git stash"
  sh "git checkout gh-pages"
  sh "cp -rp doc/* ."
  sh 'git commit -a -m "Regenerated docs"'
  sh "git push origin gh-pages"
  sh "git checkout #{branch}"
  sh "git stash apply"
end
