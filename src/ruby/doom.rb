#!/usr/local/bin/ruby

class Lump
	attr_accessor :offset, :size, :name
	def initialize(offset=nil, size=nil, name=nil)
		@offset = offset
		@size = size
		@name = name
	end
	def read(array)
			@offset = Wad.convert_long(array.slice(0,4))
			@size = Wad.convert_long(array.slice(4,4))
			@name = Wad.convert_string(array.slice(8,8))	
	end
	def to_s
		@offset.to_s + "," + @size.to_s + "," + @name
	end
end

class Header
	attr_reader :type, :directory_offset, :lump_count
	def initialize(array)
		@type = Wad.convert_string(array.slice(0,4))
		@lump_count = Wad.convert_long(array.slice(4,4))
		@directory_offset = Wad.convert_long(array.slice(8,4))	
	end
end

class Wad
	attr_reader :lumps, :directory_offset, :lumps, :header
	def initialize(filename, verbose=false)
		@verbose = verbose
		@type = ""
		@bytes = []
		@lumps = []

		puts "Reading WAD into memory" unless !@verbose
		File.new(filename).each_byte {|b| @bytes << b }
		puts "Done reading, building the object model" unless !@verbose
	
		@header = Header.new(@bytes.slice(0,12))
	
		@header.lump_count.times {|lump_index|
			lump = Lump.new
			lump.read(@bytes.slice((lump_index*16)+@header.directory_offset,16))
			@lumps << lump
		}
	
		puts "Object model built" unless !@verbose
	end
	def pwad
		@type=="PWAD"
	end
	def byte_count
		@bytes.size
	end
	def save(filename)
		puts "Saving file" unless !@verbose
	end
	def Wad.convert_string(array)
		y=""
    array.each {|x| y << x.chr }
		y.strip
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
	puts "It's got " + w.lumps.size.to_s + " lumps, the directory starts at byte " + w.header.directory_offset.to_s
	puts "Lump".ljust(10) + "Size ".ljust(10) + "Offset".ljust(20)
	w.lumps.each {|lump|
		puts lump.name.ljust(10) + lump.size.to_s.ljust(10) + lump.offset.to_s.ljust(20)
	}
end

