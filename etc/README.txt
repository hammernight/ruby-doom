README for Ruby-DOOM

Ruby-DOOM reads and writes DOOM level maps.  

The current release  can parse any DOOM II map into an object model.  Run it like this:

./doom.rb [-v] -f simple.wad

and it'll produce a list of the lumps (things, vertexes, sectors, etc) contained within the file.

You can also write Ruby code to assemble a map, albeit quite tediously.
Please see http://ruby-doom.rubyforge.org/ for more detailed information.
