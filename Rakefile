require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/clean'
require 'rcov/rcovtask'
require 'yard'

CLEAN	<< "pkg" << "docs" << "coverage"

task :default => :test

Rake::TestTask.new(:test) { |t| t.pattern = 'test/**/*_test.rb' }
Rake::GemPackageTask.new(eval(File.read("friendly_id.gemspec"))) { |pkg| }
Rake::RDocTask.new do |r|
	r.rdoc_dir = "docs"
	r.main = "README.rdoc"
	r.rdoc_files.include "README.rdoc", "History.txt", "lib/**/*.rb"
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', "README.rdoc", "History.txt"]
  t.options = ["--output-dir=docs"]
end

Rcov::RcovTask.new do |r|
	r.test_files = FileList['test/*_test.rb']
	r.verbose = true
  r.rcov_opts << "--exclude gems/*"
end
