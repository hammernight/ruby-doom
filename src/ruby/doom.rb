#!/usr/local/bin/ruby

class Lump
	def read(bytes)
		@bytes = bytes
	end
	def write
		@bytes
	end
end

class DirectoryEntry
	SIZE=16
	attr_accessor :offset, :size, :name
	def read(array)
			@offset = Wad.unmarshal_long(array.slice(0,4))
			@size = Wad.unmarshal_long(array.slice(4,4))
			@name = array.slice(8,8).pack("C*").strip
	end
	def write
		Wad.marshal_long(@offset) + Wad.marshal_long(@size) + Wad.marshal_string(@name)
	end
	def create_lump(bytes)
		lump=Lump.new
		lump.read(bytes.slice(@offset, @size))
		lump
	end
	def to_s
		@offset.to_s + "," + @size.to_s + "," + @name
	end
end

class Header
	SIZE=12
	attr_reader :type, :directory_offset, :lump_count
	def read(array)
		@type = array.slice(0,4).pack("C*").strip
		@lump_count = Wad.unmarshal_long(array.slice(4,4))
		@directory_offset = Wad.unmarshal_long(array.slice(8,4))	
	end
	def write
		@type.unpack("C*") + Wad.marshal_long(@lump_count) + Wad.marshal_long(@directory_offset)
	end
end

class Wad
	attr_reader :directory_entries, :directory_offset, :header, :bytes
	def initialize(verbose=false)
		@verbose = verbose
		@bytes = []
		@directory_entries = []
		@lumps = []
	end
	def read(filename)
		puts "Reading WAD into memory" unless !@verbose
		File.new(filename).each_byte {|b| @bytes << b }
		puts "Done reading, building the object model" unless !@verbose
		@header = Header.new
		@header.read(@bytes.slice(0,Header::SIZE))
		@header.lump_count.times {|directory_entry_index|
			de = DirectoryEntry.new
			de.read(@bytes.slice((directory_entry_index*DirectoryEntry::SIZE)+@header.directory_offset,DirectoryEntry::SIZE))
			@directory_entries << de
			@lumps << de.create_lump(@bytes)
		}
		puts "Object model built" unless !@verbose
	end
	def write
		[]
	end
	def pwad
		@header.type=="PWAD"
	end
	def byte_count
		@bytes.size
	end
	def save(filename)
		puts "Saving file" unless !@verbose
		out = @header.save
		# TODO	
		# concat lumps
		# concat directory
		puts "Done" unless !@verbose
	end
	def Wad.marshal_string(n)
		arr = n.unpack("C8").compact
		if arr.size < 8
			arr += Array.new(8-arr.size, 0)
		end
		arr
	end
	def Wad.marshal_long(n)
		[n].pack("N").unpack("C4").reverse
	end
	def Wad.unmarshal_long(a)
		a.pack("C4").unpack("V")[0]
	end
end

if __FILE__ == $0
	file = ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
	w = Wad.new(true)
	w.read(file)
	puts "The file " + file + " is a " + w.byte_count.to_s + " byte patch WAD" unless !w.pwad
	puts "It's got " + w.directory_entries.size.to_s + " lumps, the directory starts at byte " + w.header.directory_offset.to_s
	puts "Lump".ljust(10) + "Size ".ljust(6) + "Offset".ljust(10)
	w.directory_entries.each {|lump|
		puts lump.name.ljust(10) + lump.size.to_s.ljust(6) + lump.offset.to_s.ljust(10)
	}
end
