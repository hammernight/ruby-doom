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
	def test_short_readwrite
		assert(Wad.unmarshal_short([2,1]) == 258, "unmarshalling short failed")
		assert(Wad.marshal_short(258) == [2,1], "marshalling short failed")
	end
	def test_readwrite_simple
		working = W1
		w = Wad.new
		w.read(working.name)
		assert(w.byte_count == working.bytes, "wrong byte count")
		assert(w.pwad, "pwad not verified")
		assert(w.write.size == w.byte_count-1, "size difference, " + w.write.size.to_s + " != " + w.byte_count.to_s)
	end
	def test_readwrite_stepstep
		working = W2
		w = Wad.new
		w.read(working.name)
		assert(w.byte_count == working.bytes, "wrong byte count")
		assert(w.pwad, "pwad not verified")
		assert(w.write.size == w.byte_count, "size difference, " + w.write.size.to_s + " != " + w.byte_count.to_s)
		assert(w.write == w.bytes, "content difference")
	end
end

class LumpTest < Test::Unit::TestCase
	def test_init
		lump = Lump.new("FOO")
		lump.read([1,2,3])
		assert(lump.write == [1,2,3], "lump byte array doesn't stay const")
		assert(lump.name == "FOO", "lump name corrupted")
	end
end

class ThingTest < Test::Unit::TestCase
	def test_type
		t = Thing.new
		t.read([224,0,96,254,0,0,1,0,7,0])	
		assert(t.type_id == 1, "type id decode failed")
	end
end
