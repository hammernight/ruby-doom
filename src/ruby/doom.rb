#!/usr/local/bin/ruby

class Wad
	attr_reader :bytes
	def initialize(filename, verbose=false)
		@verbose = verbose
		@type = ""
		@bytes = []
		puts "Parsing WAD file " + filename unless !@verbose

		file = File.new(filename)
		file.each_byte {|b|
			@bytes << b
		}
		puts "Done parsing" unless !@verbose
	end
	def pwad
		type = ""
		0.upto(3) {|x|
			type << @bytes[x].chr
		}
		type=="PWAD"
	end
	def lumps
		convert_long(@bytes.slice(4,4))
	end
	def directory_offset
		convert_long(@bytes.slice(8,4))
	end
	def convert_long(array)
		y=""
		array.each {|x| y << x.chr } 
		y.unpack("V")
	end
end

if __FILE__ == $0
	w = Wad.new("../../test_wads/simple.wad", true)
	puts "It's a patch WAD" unless !w.pwad
	puts "It's got " + w.lumps.to_s + " lumps"
	puts "The directory offset is " + w.directory_offset.to_s
end

