#!/usr/local/bin/ruby

require "test/unit"
require "doom.rb"

class HeaderTest < Test::Unit::TestCase
	def test_read
		data = [80, 87, 65, 68, 11, 0, 0, 0, 212, 2, 0, 0]
		h = Header.new()
		h.read(data)
		assert(h.type == "PWAD", "wrong type")
		assert(h.directory_offset == 724, "wrong directory offset")
		assert(h.lump_count == 11, "wrong lump count")
	end
	def test_write
		data = [80, 87, 65, 68, 11, 0, 0, 0, 212, 2, 0, 0]
		h = Header.new()
		h.read(data)
		assert(h.write == data, "didn't marshal right")
	end
end

class DirectoryEntryTest < Test::Unit::TestCase
	def test_read
		data = [13, 0, 0, 0, 10, 0, 0, 0, 84, 72, 73, 78, 71, 83, 0, 0]
		d = DirectoryEntry.new
		d.read(data)
		assert(d.name == "THINGS", "wrong name")
		assert(d.offset == 13, "wrong offset")
		assert(d.size == 10, "wrong size")
	end
	def test_write
		data = [13, 0, 0, 0, 10, 0, 0, 0, 84, 72, 73, 78, 71, 83, 0, 0]
		d = DirectoryEntry.new
		d.read(data)
		assert(d.write == data, "didn't marshal right")
	end
end

class WadFile
	attr_accessor :name, :bytes
	def initialize(name,bytes)
		@name=name
		@bytes=bytes
	end
end

class WadTest < Test::Unit::TestCase
	W1 = WadFile.new("../../test_wads/simple.wad", 900)
	def test_readwrite_simple
		working = W1
		w = Wad.new
		w.read(working.name)
		bytes = w.write
		assert(w.bytes.size == working.bytes, "wrong byte count")
		assert(w.header.type, "pwad not verified")
		assert(bytes.size == w.bytes.size-1, "size difference, " + bytes.size.to_s + " != " + w.bytes.size.to_s)
	end
end

class LumpTest < Test::Unit::TestCase
	def test_init
		lump = UndecodedLump.new("FOO")
		lump.read([1,2,3])
		assert(lump.write == [1,2,3], "lump byte array doesn't stay const")
		assert(lump.name == "FOO", "lump name corrupted")
	end
end

class ThingsTest <  Test::Unit::TestCase
  def test_one
    things = Things.new
    things.read(ThingTest::BYTES + ThingTest::BYTES)
    assert(things.items.size == 2, "wrong size")
  end
end

class ThingTest < Test::Unit::TestCase
	BYTES=[224,0,96,254,0,0,1,0,7,0]
	def test_read
		t = Thing.new
		t.read(BYTES)	
		assert(t.type_id == 1, "type id decode failed")
		assert(t.location.x == 224, "location.x decode failed")
		assert(t.location.y == -416, "location.y decode failed")
		assert(t.facing_angle == 0, "facing angle decode failed")
	end
	def test_write
		t = Thing.new
		t.read(BYTES)	
		t.facing_angle = 90
		assert(t.write == [224,0,96,254,90,0,1,0,7,0], "write failed")
	end
end

class DictionaryTest  < Test::Unit::TestCase
	def test_id_to_name
		assert(Dictionary.get.name_for_type_id(1) == "Player 1", "couldn't find name for id == 1")
		assert(Dictionary.get.name_for_type_id(-999) == "Unknown thing", "unknown key should return 'Unknown'")
	end
	def test_name_to_id
		assert(Dictionary.get.type_id_for_name("Player 1") == 1, "couldn't find id for name = 'player 1' == 1")
	end
	def test_angle
		assert(Dictionary.get.direction_for_angle(22) == "east", "east failed")
		assert(Dictionary.get.direction_for_angle(100) == "north", "north failed")
		assert(Dictionary.get.direction_for_angle(190) == "west", "west failed")
		assert(Dictionary.get.direction_for_angle(310) == "south", "south failed")
	end
end

class LinedefsTest < Test::Unit::TestCase
	def test_basic
		linedefs = Linedefs.new
		assert(linedefs.name == Linedefs::NAME, "Wrong name")
	end
end

class VertexTest < Test::Unit::TestCase
	def test_init
		v=Vertex.new
		assert(v.location == nil, "location should be null if not set")
		v=Vertex.new(Point.new(1,1))
		assert(v.location.x == 1 && v.location.y == 1, "initial point setting wrong")
	end
end

class SectorsTest < Test::Unit::TestCase
	def test_add
		sectors=Sectors.new
		s=Sector.new
		sectors.add(s)
		assert(sectors.items.size == 1, "Adding a Sector didn't increase size")
		assert(s.id == 0, "Sector id didn't get set")
		sectors.add(s)
		assert(s.id == 1, "Second sector id didn't get set")
	end
end

class VertexesTest < Test::Unit::TestCase
	def test_add
		verts=Vertexes.new
		v=Vertex.new(Point.new(1,1))
		verts.add(v)
		assert(verts.items.size == 1, "Adding a Vertex didn't increase size")
		assert(v.id == 0, "Vertex id didn't get set")
		verts.add(v)
		assert(v.id == 1, "Second vertex id didn't get set")
	end
end

class CodecTest  < Test::Unit::TestCase
	def test_decode
		assert(Codec.decode("s", ThingTest::BYTES.slice(0,2))[0] == 224, "bad short decode") 
		assert(Codec.decode("s", [255,255])[0] == -1, "bad signed short decode") 
		assert(Codec.decode("l", [13, 0, 0, 0])[0] == 13, "bad long decode") 
		assert(Codec.decode("4", [84, 72, 73, 78])[0] == "THIN", "bad 4 byte string decode") 
		assert(Codec.decode("8", [84, 72, 73, 78, 71, 83, 0, 0])[0] == "THINGS", "bad 8 byte string decode") 
	end
	def test_encode
		assert(Codec.encode("s", [224]) == ThingTest::BYTES.slice(0,2), "bad short decode")
		assert(Codec.encode("l", [13]) == [13,0,0,0], "bad long decode")
		assert(Codec.encode("4", ["THIN"]) == [84, 72, 73, 78], "bad 4 byte string decode")
		assert(Codec.encode("8", ["THINGS"]) == [84, 72, 73, 78, 71, 83, 0, 0], "bad 8 byte string decode")
	end
	def test_string_readwrite
		assert(Codec.unmarshal_string([84, 72, 73, 78, 71, 83, 0, 0]) == "THINGS", "unmarshalling string failed")
		assert(Codec.marshal_string("THINGS",8) == [84, 72, 73, 78, 71, 83, 0, 0], "marshalling string failed")
	end
end

class PathTest < Test::Unit::TestCase
	TEST="e500/n200/w500/s200"
	def test_parse
		p = Path.new(Point.new(0,0),TEST)
		assert(p.segments.size == 4, "Wrong parts")
		assert(p.segments[2] == "w500", "wrong order")
	end
	def test_add
		p = Path.new(Point.new(0,0),"")
		assert(p.path == "", "initial path wrong")
		p.add "e200/"
		assert(p.path == "e200/", "adding path failed")
		p.add("e100/",2)
		assert(p.path == "e200/e100/e100/", "adding multiple paths failed: " + p.path)
	end
	def test_visit
		p = Path.new(Point.new(0,0),TEST)
		@points = []
		p.visit(self)
	assert(@points.size == 4, "wrong number of callbacks")
	end
	def line_to(p)
		@points << p
	end
end

class PathCompilerTest < Test::Unit::TestCase
	def test_sectors
		pc = PathCompiler.new(Path.new(Point.new(0,0),PathTest::TEST))
		s = pc.lumps.find {|x| x.name == Sectors::NAME }	
		assert(s.items[0].id == 0, "wrong id")
		assert(s.items[0].id == 0, "wrong id when called twice, should return same sector")
	end
	def test_sidedefs
		pc = PathCompiler.new(Path.new(Point.new(0,0),PathTest::TEST))
		s = pc.lumps.find {|x| x.name == Sidedefs::NAME }	
		assert(s.items.size == 4, "wrong count")
		assert(s.items[0].sector_id == 0, "wrong sector id")
		assert(s.items[0].id == 0, "wrong sidedef id")
		assert(s.items[1].id == 1, "wrong sidedef id")
	end
	def test_linedefs
		pc = PathCompiler.new(Path.new(Point.new(0,0),PathTest::TEST))
		ld = pc.lumps.find {|x| x.name == Linedefs::NAME }	
		assert(ld.items.size == 4, "wrong count")
		assert(ld.items[0].right_sidedef.id == 0, "wrong first sidedef")
		assert(ld.items[3].right_sidedef.id == 3, "wrong fourth sidedef")
		assert(ld.items[0].start_vertex.id == 0, "wrong start vertex on first linedef")
		assert(ld.items[0].end_vertex.id == 1, "wrong end vertex on first linedef")
		assert(ld.items[3].start_vertex.id == 3, "wrong start vertex on last linedef")	
		assert(ld.items[3].end_vertex.id == 0, "wrong end vertex on last linedef")
	end
	def test_vertexes
		pc = PathCompiler.new(Path.new(Point.new(0,0),PathTest::TEST))
		v = pc.lumps.find {|x| x.name == Vertexes::NAME }	
		assert(v.items.size == 4, "wrong vert count")
		assert(v.items[0].location.x == 0, "wrong initial x for vertex 1")
		assert(v.items[0].location.y == 0, "wrong y for vertex 1")
		assert(v.items[1].location.x == 500, "wrong x for vertex 2")
		assert(v.items[1].location.y == 0, "wrong y for vertex 2")
		assert(v.items[2].location.x == 500, "wrong x for vertex 3")
		assert(v.items[2].location.y == 200, "wrong y for vertex 3")
		assert(v.items[3].location.x == 0, "wrong x for vertex 4")
		assert(v.items[3].location.y == 200, "wrong y for vertex 4")
	end
end

class PointTest < Test::Unit::TestCase
	def test_lineto
		p = Point.new(0,0)
		p1 = Point.new(3,0)
		assert(p.lineto(p1).size == 5, "not enough points")
		assert(p.lineto(p1)[0].x == 0 && p.lineto(p1)[0].y == 0, "wrong start")
		assert(p.lineto(p1)[1].x == 1 && p.lineto(p1)[1].y == 0, "wrong pt1 " + p.lineto(p1)[1].to_s)
	end
	def test_lineto_negy
		p = Point.new(0,3)
		p1 = Point.new(0,0)
		assert(p.lineto(p1)[1].x == 0 && p.lineto(p1)[1].y == 2, "wrong pt1 " + p.lineto(p1)[1].to_s)
	end
	def test_lineto_negx
		p = Point.new(3,0)
		p1 = Point.new(0,0)
		assert(p.lineto(p1)[1].x == 2 && p.lineto(p1)[1].y == 0, "wrong pt1 " + p.lineto(p1)[1].to_s)
	end
	def test_slope
		p = Point.new(0,0)
		assert(p.slope_to(Point.new(0,3)) == nil, "line straight north should have infinite (nil) slope")
		assert(p.slope_to(Point.new(3,0)) == 0, "line straight east should have 0 slope")
	end
	def test_distance
		p = Point.new(0,0)
		assert(p.distance_to(Point.new(0,3)) == 3, "straight line distance failed")
		assert((p.distance_to(Point.new(3,3))*10).to_i == 42, "diagonal line distance failed ")
		assert(p.distance_to(Point.new(-3,0)) == 3, "just checking")
	end
	
end
