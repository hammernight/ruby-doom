#!/usr/local/bin/ruby

require "doom.rb"

puts "Creating a simple rectangle using clockwise linedefs"
w = Wad.new(true)

w.lumps << UndecodedLump.new("MAP01")

t = Things.new
t.add_player Point.new(100,400)
w.lumps << t

v = Vertexes.new
v1 = v.add Vertex.new(Point.new(60, 500))
v2 = v.add Vertex.new(Point.new(600, 500))
v3 = v.add Vertex.new(Point.new(600, 200))
v4 = v.add Vertex.new(Point.new(60, 200))
w.lumps << v

sectors = Sectors.new
s1 = sectors.add Sector.new
w.lumps << sectors

sidedefs = Sidedefs.new
sd1 = sidedefs.add Sidedef.new
sd1.sector_id = s1.id
sd2 = sidedefs.add Sidedef.new
sd2.sector_id = s1.id
sd3 = sidedefs.add Sidedef.new
sd3.sector_id = s1.id
sd4 = sidedefs.add Sidedef.new
sd4.sector_id = s1.id
w.lumps << sidedefs

linedefs = Linedefs.new
linedefs.add Linedef.new(v1,v2,sd1)
linedefs.add Linedef.new(v2,v3,sd2)
linedefs.add Linedef.new(v3,v4,sd3)
linedefs.add Linedef.new(v4,v1,sd4)
w.lumps << linedefs

w.write("new.wad")
