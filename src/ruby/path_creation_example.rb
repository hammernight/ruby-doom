#!/usr/local/bin/ruby

require "doom.rb"
puts "Creating a simple rectangle using an encoded path"
w = Wad.new(true)
w.lumps << UndecodedLump.new("MAP01")
t = Things.new
t.add_player Point.new(50,100)
w.lumps << t

p = Path.new(0, 500, "e600/n200/e400/s200/e800/s500/w800/s200/w400/n200/w600/n500")
w.lumps << p.vertexes
w.lumps << p.sectors
w.lumps << p.sidedefs
w.lumps << p.linedefs

w.write("new.wad")
