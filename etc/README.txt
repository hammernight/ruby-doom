README for Ruby-DOOM

Ruby-DOOM reads and writes DOOM level maps.  

The current release can assemble a map using a Ruby code and a "path
specification", like this:

=============================
require "doom.rb"
puts "Creating a simple rectangle using an encoded path"
w = Wad.new(true)
w.lumps << UndecodedLump.new("MAP01")
t = Things.new
t.add_player Point.new(50,900)
w.lumps << t

# this path amounts to "east 300, then north 200, then east 300" etc., etc.
p = Path.new(0, 1000, "e300/n200/e300/s200/e800/s500/w800/s200/w300/n200/w300/n400")

w.lumps << p.vertexes
w.lumps << p.sectors
w.lumps << p.sidedefs
w.lumps << p.linedefs
w.write("new.wad")
=============================

Incidentally, Ruby-DOOM can also parse any DOOM II map into an object model.  Run it like this:

./doom.rb [-v] -f simple.wad

and it'll produce a list of the lumps (things, vertexes, sectors, etc) contained within the file.

Please see http://ruby-doom.rubyforge.org/ for more detailed information.
