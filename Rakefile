#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

task :default => :spec

desc "Starts a server up"
task :start do
  puts 'Starting flipper on port 9999'
  `bundle exec rackup examples/basic.ru -p 9999`
end
