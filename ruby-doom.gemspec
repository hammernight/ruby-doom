#!/usr/local/bin/ruby

require 'rubygems'

spec = Gem::Specification.new do |s|
	s.name = "ruby-doom"
	s.version = "0.8"
	s.platform = Gem::Platform::RUBY
	s.summary = "Ruby-DOOM provides a scripting API for creating DOOM maps. It also provides higher-level APIs to make map creation easier."
	s.files << "src/ruby/example.rb"
	s.files << "src/ruby/doom.rb"
	s.files << "etc/README"
	s.files << "etc/CHANGELOG"
	s.files << "etc/LICENSE"
	s.require_path = "lib"
	s.autorequire = "ruby-doom"
	s.author = "Tom Copeland"
	s.email = "tom@infoether.com"
	s.rubyforge_project = "ruby-doom"
	s.homepage = "http://ruby-doom.rubyforge.org/"	
end

 Gem::Builder.new(spec).build if $0 == __FILE__
