#!/usr/local/bin/ruby


class Lump
	attr_accessor :offset, :size, :name
	def initialize(offset, size, name)
		@offset = offset
		@size = size
		@name = name
	end
	def to_s
		@offset.to_s + "," + @size.to_s + "," + @name
	end
end

class Wad
	attr_reader :bytes, :lumps, :directory_offset, :lumps
	def initialize(filename, verbose=false)
		@verbose = verbose
		@type = ""
		@bytes = []
		@lumps = []

		puts "Reading WAD into memory" unless !@verbose

		file = File.new(filename)
		file.each_byte {|b|
			@bytes << b
		}

		puts "Done reading, building the object model" unless !@verbose

		@type = convert_string(@bytes.slice(0,4))
		lump_count = convert_long(@bytes.slice(4,4))
		@directory_offset = convert_long(@bytes.slice(8,4))
		
		ptr = @directory_offset
		while ptr < byte_count-15
			@lumps << Lump.new(convert_long(@bytes.slice(ptr,4)), convert_long(@bytes.slice(ptr+4,4)), convert_string(@bytes.slice(ptr+8,8)))	
			ptr += 16
		end	
		puts "Object model built" unless !@verbose
	end
	def pwad
		@type=="PWAD"
	end
	def byte_count
		@bytes.size
	end
	def convert_string(array)
		y=""
    array.each {|x| y << x.chr }
		y.strip
	end
	def convert_long(array)
		y=""
		array.each {|x| y << x.chr } 
		y.unpack("V")[0]
	end
end

if __FILE__ == $0
	file = ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
	w = Wad.new(file, true)
	puts "The file " + file + " is a " + w.byte_count.to_s + " byte patch WAD" unless !w.pwad
	puts "It's got " + w.lumps.size.to_s + " lumps"
	puts "The directory starts at byte " + w.directory_offset.to_s
	puts "Lump name".ljust(10) + "Size (bytes) ".ljust(15) + "Starts at offset".ljust(20)
	w.lumps.each {|lump|
		puts lump.name.ljust(10) + lump.size.to_s.ljust(15) + lump.offset.to_s.ljust(20)
	}
end

