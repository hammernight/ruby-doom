README for Ruby-DOOM

Ruby-DOOM reads and writes DOOM level maps.  

The current release can assemble a map using a Ruby code and a "path
specification", like this:

=============================
m = SimpleLineMap.new(Path.new(0, 1000, "e300/n200/e300/s200/e800/s500/w800/s200/w300/n200/w300/n400"))
m.set_player Point.new(50,900)
550.step(900, 40) {|x|
 m.add_barrel Point.new(x,900)
}
m.create_wad("new.wad")
=============================

Incidentally, Ruby-DOOM can also parse any DOOM II map into an object model.  Run it like this:

./doom.rb [-v] -f simple.wad

and it'll produce a list of the lumps (things, vertexes, sectors, etc) contained within the file.

Please see http://ruby-doom.rubyforge.org/ for more detailed information.
