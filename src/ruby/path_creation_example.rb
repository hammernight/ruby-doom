#!/usr/local/bin/ruby

require "doom.rb"
puts "Creating a simple rectangle using an encoded path"
w = Wad.new(true)
w.lumps << UndecodedLump.new("MAP01")
t = Things.new
t.add_player Point.new(50,900)
w.lumps << t

p = Path.new(0, 1000, "e300/n200/e300/s200/e800/s500/w800/s200/w300/n200/w300/n400")
w.lumps << p.vertexes
w.lumps << p.sectors
w.lumps << p.sidedefs
w.lumps << p.linedefs

w.write("new.wad")

if ARGV.include?("-nethack")
  puts p.nethack
  puts "Map generated from " + p.to_s
end
