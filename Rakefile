require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # Rubocop not available
end

task :default => :spec

desc "Run a console with code_sage loaded"
task :console do
  require 'pry'
  require_relative 'lib/code_sage'
  Pry.start
end 