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
	W2 = WadFile.new("../../test_wads/stepstep.wad", 59436)
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
	def test_short_readwrite
		assert(Codec.unmarshal_short([2,1]) == 258, "unmarshalling short failed")
		assert(Codec.marshal_short(258) == [2,1], "marshalling short failed")
	end
	def test_string_readwrite
		assert(Codec.unmarshal_string([84, 72, 73, 78, 71, 83, 0, 0]) == "THINGS", "unmarshalling string failed")
		assert(Codec.marshal_string("THINGS",8) == [84, 72, 73, 78, 71, 83, 0, 0], "marshalling string failed")
	end
end
