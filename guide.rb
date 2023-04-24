#!/usr/bin/env ruby

# This script generates the Guide.md file included in the Yard docs.

def comments_from path
  path = File.expand_path("../lib/friendly_id/#{path}", __FILE__)
  matches = File.read(path).match(/\n# @guide begin(.*)\n# @guide end/m)

  return if matches.nil?

  match = matches[1].to_s
  match.split("\n").map { |x| x.sub(/^\s*# /, "") }.reject { |x| x =~ /^@/ }.join("\n").strip
end

File.open(File.expand_path("../Guide.md", __FILE__), "w:utf-8") do |guide|
  ["../friendly_id.rb", "base.rb", "finders.rb", "slugged.rb", "history.rb",
    "scoped.rb", "simple_i18n.rb", "reserved.rb"].each do |file|
    guide.write comments_from file
    guide.write "\n"
  end
end
