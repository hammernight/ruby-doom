#!/usr/local/bin/ruby

require "doom.rb"
puts "Creating a map using a repeated path"

p = Path.new(0, 1000)
p.add("e200/n200/e200/s200/e200/",6)
p.add("s400/")
p.add("w200/s200/w200/n200/w200/",6)
p.add("n400/")

m = SimpleLineMap.new p
m.set_player Point.new(50,900)
m.create_wad("new.wad")

if ARGV.include?("-nethack")
  puts p.nethack(40)
  puts "Map generated from " + p.to_s
end

