#!/usr/local/bin/ruby

require "test/unit"
require "doom.rb"

class HeaderTest < Test::Unit::TestCase
	def test_init
		data = [80, 87, 65, 68, 11, 0, 0, 0, 212, 2, 0, 0, 0]
		h = Header.new(data)
		assert(h.type == "PWAD", "wrong type")
		assert(h.directory_offset == 724, "wrong directory offset")
		assert(h.lump_count == 11, "wrong lump count")
		#puts h.save
		#assert(h.save == data, "didn't marshal right")
	end
end

