#!/usr/local/bin/ruby

class Point
	attr_accessor :x, :y
	def initialize(x,y)
		@x=x
		@y=y
	end
	def to_s
		@x.to_s + "," + @y.to_s
	end
end

class Lump
	attr_reader :name
	def initialize(name)
		@name = name
	end
	def read(bytes)
		@bytes = bytes
	end
	def write
		@bytes
	end
	def size
		@bytes.size
	end
end

class Things < Lump
  BYTES_EACH=10
  NAME="THINGS"
	attr_reader :things
  def initialize
    super(NAME)
    @things = []
  end
  def read(bytes)
    super(bytes)
    (@bytes.size / BYTES_EACH).times {|thing_index|
      thing = Thing.new
      thing.read(@bytes.slice(thing_index*BYTES_EACH, BYTES_EACH))
      @things << thing
    }
  end
end

class Thing
  attr_reader :type_id, :location
  attr_accessor :facing_angle
  def read(bytes)
    @type_id = Wad.unmarshal_short(bytes.slice(6,2))
    @facing_angle = Wad.unmarshal_short(bytes.slice(4,2))
    @location = Point.new(Wad.unmarshal_short(bytes.slice(0,2)), Wad.unmarshal_short(bytes.slice(2,2)))
    @flags = Wad.unmarshal_short(bytes.slice(8,2))
  end
	def write
		Wad.marshal_short(@location.x) + Wad.marshal_short(@location.y) + Wad.marshal_short(@facing_angle) + Wad.marshal_short(@type_id) + Wad.marshal_short(@flags)
	end
end


class DirectoryEntry
	SIZE=16
	attr_accessor :offset, :size, :name
	def initialize(offset=nil,size=nil,name=nil)
		@offset = offset
		@size = size
		@name = name
	end
	def read(array)
			@offset = Wad.unmarshal_long(array.slice(0,4))
			@size = Wad.unmarshal_long(array.slice(4,4))
			@name = Wad.unmarshal_string(array.slice(8,8))
	end
	def write
		Wad.marshal_long(@offset) + Wad.marshal_long(@size) + Wad.marshal_string(@name,8)
	end
	def create_lump(bytes)
		lump=nil
		if @name == Things::NAME
			lump=Things.new
		else
			lump=Lump.new(@name)
		end
		lump.read(bytes.slice(@offset, @size))
		lump
	end
	def to_s
		@offset.to_s + "," + @size.to_s + "," + @name
	end
end

class Header
	SIZE=12
	attr_reader :type, :lump_count
	attr_accessor :directory_offset
	def read(array)
		@type = Wad.unmarshal_string(array.slice(0,4))
		@lump_count = Wad.unmarshal_long(array.slice(4,4))
		@directory_offset = Wad.unmarshal_long(array.slice(8,4))	
	end
	def write
		Wad.marshal_string(@type,4) + Wad.marshal_long(@lump_count) + Wad.marshal_long(@directory_offset)
	end
end

class Wad
	attr_reader :directory_offset, :header, :bytes, :lumps
	def initialize(verbose=false)
		@verbose = verbose
		@bytes = []
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
			@lumps << de.create_lump(@bytes)
		}
		puts "Object model built" unless !@verbose
	end
	def pwad
		@header.type=="PWAD"
	end
	def byte_count
		@bytes.size
	end
	def write(filename=nil)
		puts "Writing WAD" unless !@verbose
		out = []
		ptr = Header::SIZE
		entries = []
		@lumps.each {|lump|
			entries << DirectoryEntry.new(ptr, lump.size, lump.name)
			out += lump.write
			ptr += lump.size
		}
		entries.each {|e| out += e.write }
		# now go back and fill in the directory offset in the header
		header.directory_offset = ptr
		out = header.write + out
		File.open(filename, "w") {|f| out.each {|b| f.putc(b) } } unless filename == nil
		puts "Done" unless !@verbose
		return out
	end
	def Wad.unmarshal_string(a)
		a.pack("C*").strip
	end
	def Wad.marshal_string(n,len)
		arr = n.unpack("C#{len}").compact
		if arr.size < len
			arr += Array.new(len-arr.size, 0)
		end
		arr
	end
	def Wad.unmarshal_long(a)
		a.pack("C4").unpack("V")[0]
	end
	def Wad.marshal_long(n)
		[n].pack("N").unpack("C4").reverse
	end
	def Wad.unmarshal_short(a)
		a.reverse.pack("C2").unpack("n")[0]
	end
	def Wad.marshal_short(s)
		[s].pack("n").unpack("C2").reverse
	end
end

if __FILE__ == $0
  file = ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
  w = Wad.new(true)
  w.read(file)
  if ARGV.include?("-turn")
    w.things.player.facing_angle = 90
  else
    puts "The file " + file + " is a " + w.byte_count.to_s + " byte patch WAD" unless !w.pwad
    puts "It's got " + w.lumps.size.to_s + " lumps, the directory started at byte " + w.header.directory_offset.to_s
    puts "Lump".ljust(10) + "Size ".ljust(6)
    w.lumps.each {|lump|
      puts lump.name.ljust(10) + lump.size.to_s.ljust(6)
    }
  end
  w.write("out.wad")
end

