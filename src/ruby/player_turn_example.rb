#!/usr/local/bin/ruby

require "doom"

w = Wad.new(ARGV.include?("-v"))
w.read ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
puts "Changing player angle" unless !ARGV.include?("-v")
w.player.facing_angle = 90
w.write "new.wad" 

