#!/usr/local/bin/ruby

require "doom.rb"
puts "Creating a map using a repeated path"

w = Wad.new(true)
w.lumps << UndecodedLump.new("MAP01")
t = Things.new
t.add_player Point.new(50,900)
w.lumps << t

p = Path.new(0, 1000, "")
p.add("e200/n200/e200/s200/e200/",8)
p.add("s400/")
p.add("w200/s200/w200/n200/w200/",8)
p.add("n400/")

w.lumps << p.vertexes
w.lumps << p.sectors
w.lumps << p.sidedefs
w.lumps << p.linedefs

w.write("new.wad")

if ARGV.include?("-nethack")
  puts p.nethack(40)
  puts "Map generated from " + p.to_s
end

