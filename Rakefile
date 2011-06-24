require 'rubygems'
require 'rake/testtask'

Rake::TestTask.new(:tests) do |t|
  t.pattern = 'test/*.rb'
  t.verbose = true
  t.warning = true
end

task :default => :tests
