require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/clean'

CLEAN << "pkg" << "docs" << "coverage" << ".yardoc"

task :default => :test

Rake::TestTask.new(:test) { |t| t.pattern = 'test/**/*_test.rb' }
Rake::GemPackageTask.new(eval(File.read("friendly_id.gemspec"))) { |pkg| }
Rake::RDocTask.new do |r|
  r.rdoc_dir = "doc"
  r.rdoc_files.include "lib/**/*.rb"
end

begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    t.options = ["--output-dir=doc"]
    t.options << '--files' << ["Guide.md", "Contributors.md", "History.md"].join(",")
  end
rescue LoadError
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |r|
    r.test_files = FileList['test/*_test.rb']
    r.verbose = true
    r.rcov_opts << "--exclude gems/*"
  end
rescue LoadError
end
