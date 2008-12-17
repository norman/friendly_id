require 'hoe'

require File.join(File.dirname(__FILE__), 'lib', 'friendly_id', 'version')

Hoe.new("friendly_id", FriendlyId::Version::STRING) do |p|
  p.rubyforge_name = "friendly-id"
  p.author = ['Norman Clarke', 'Adrian Mugnolo', 'Emilio Tagua']
  p.email = ['norman@randomba.org', 'adrian@randomba.org', 'miloops@gmail.com']
  p.summary = "A comprehensive slugging and pretty-URL plugin for Ruby on Rails."
  p.description = 'A comprehensive slugging and pretty-URL plugin for Ruby on Rails.'
  p.url = 'http://randomba.org'
  p.need_tar = true
  p.need_zip = true
  p.test_globs = ['test/**/*_test.rb']
  p.extra_deps << ['unicode', '>= 0.1']
  p.rdoc_pattern = /^(lib|bin|ext)|txt|rdoc$/
  changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = ""
end

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
