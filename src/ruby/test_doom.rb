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
		assert(h.write.slice(0,8) == data.slice(0,8), "didn't marshal right")
		assert(h.write.slice(8,12) == [0,0,0,0], "directory offset should be zero'd out for later population")
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

class WadTest < Test::Unit::TestCase
	def test_init
		w = Wad.new
		w.read("../../test_wads/stepstep.wad")
		assert(w.byte_count == 59436, "wrong byte count")
		assert(w.pwad, "pwad not verified")
		assert(w.write.size == w.bytes.size, "write failed")
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
