require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/clean'

CLEAN	<< "pkg" << "docs" << "coverage"

task :default => :test

Rake::TestTask.new(:test) { |t| t.pattern = 'test/**/*_test.rb' }
Rake::GemPackageTask.new(eval(File.read("friendly_id.gemspec"))) { |pkg| }
Rake::RDocTask.new do |r|
	r.rdoc_dir = "docs"
	r.main = "README.rdoc"
	r.rdoc_files.include "README.rdoc", "History.txt", "lib/**/*.rb"
end

begin
  require "yard"
  YARD::Rake::YardocTask.new do |t|
    t.options = ["--output-dir=docs", "--private"]
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
