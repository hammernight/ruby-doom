#!/usr/local/bin/ruby

class DirectoryEntry
	SIZE=16
	attr_accessor :offset, :size, :name
	def initialize(offset=nil, size=nil, name=nil)
		@offset = offset
		@size = size
		@name = name
	end
	def read(array)
			@offset = Wad.convert_long(array.slice(0,4))
			@size = Wad.convert_long(array.slice(4,4))
			@name = array.slice(8,8).pack("C*").strip
	end
	def to_s
		@offset.to_s + "," + @size.to_s + "," + @name
	end
end

class Header
	SIZE=12
	attr_reader :type, :directory_offset, :lump_count
	def initialize(array)
		@type = array.slice(0,4).pack("C*").strip
		@lump_count = Wad.convert_long(array.slice(4,4))
		@directory_offset = Wad.convert_long(array.slice(8,4))	
	end
	def save
		@type.unpack("C*")
	end
end

class Wad
	attr_reader :directory_entries, :directory_offset, :lumps, :header
	def initialize(filename, verbose=false)
		@verbose = verbose
		@bytes = []
		@directory_entries = []

		puts "Reading WAD into memory" unless !@verbose
		File.new(filename).each_byte {|b| @bytes << b }
		puts "Done reading, building the object model" unless !@verbose
	
		@header = Header.new(@bytes.slice(0,Header::SIZE))
	
		@header.lump_count.times {|directory_entry_index|
			de = DirectoryEntry.new
			de.read(@bytes.slice((directory_entry_index*DirectoryEntry::SIZE)+@header.directory_offset,DirectoryEntry::SIZE))
			@directory_entries << de
		}
	
		puts "Object model built" unless !@verbose
	end
	def pwad
		@header.type=="PWAD"
	end
	def byte_count
		@bytes.size
	end
	def save(filename)
		puts "Saving file" unless !@verbose
		out = []
		out += @header.save
		# TODO	
		puts "Done" unless !@verbose
	end
	def Wad.convert_long(array)
		y=""
		array.each {|x| y << x.chr } 
		y.unpack("V")[0]
	end
end

if __FILE__ == $0
	file = ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
	w = Wad.new(file, true)
	puts "The file " + file + " is a " + w.byte_count.to_s + " byte patch WAD" unless !w.pwad
	puts "It's got " + w.directory_entries.size.to_s + " lumps, the directory starts at byte " + w.header.directory_offset.to_s
	puts "Lump".ljust(10) + "Size ".ljust(6) + "Offset".ljust(10)
	w.directory_entries.each {|lump|
		puts lump.name.ljust(10) + lump.size.to_s.ljust(6) + lump.offset.to_s.ljust(10)
	}
end

