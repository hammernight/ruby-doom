#!/usr/local/bin/ruby

require "doom.rb"

puts "Creating a simple map using an encoded path"

m = SimpleLineMap.new(Path.new(Point.new(0, 1000), "e300/n200/e300/s200/e800/s500/w800/s200/w300/n200/w300/n400"))
m.set_player Point.new(50,900)
550.step(900, 40) {|x|
	m.add_barrel Point.new(x,900)
}
m.create_wad("new.wad")

if ARGV.include?("-nethack")
  puts m.nethack
  puts "Map generated from " + m.path.to_s
end
