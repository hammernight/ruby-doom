#!/usr/local/bin/ruby

class Dictionary
	def Dictionary.get
		if @self == nil
			@self = Dictionary.new
		end
		return @self
	end
	def initialize
		@type_id_to_name=Hash.new("Unknown thing")
		@type_id_to_name[1]="Player 1"
	end
	def name_for_type_id(id) 
		@type_id_to_name[id]
	end
	def direction_for_angle(angle)
		case angle
		when 0..45 then return "east"
		when 46..135 then return "north"
		when 136..225 then return "west"
		when 225..315 then return "south"
		when 316..360 then return "east"
		end
		raise "Angle must be between 0 and 360"
	end
end

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
	DIRECTION_FOR_ANGLE=Hash[{0=>"east",90=>"north",180=>"west",270=>"south"}]
  NAME="THINGS"
	attr_reader :things
  def initialize
    super(NAME)
    @things = []
  end
  def read(bytes)
    super(bytes)
    (@bytes.size / BYTES_EACH).times {|index|
      thing = Thing.new
      thing.read(@bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @things << thing
    }
  end
	def write
		out = []
		@things.each {|t| out += t.write }
		out
	end
	def player
		@things.find {|t| t.type_id == 1 } 
		raise "Couldn't find player Thing"
	end
end

class Linedefs < Lump
  BYTES_EACH=12
	attr_reader :linedefs
	NAME="LINEDEFS"
	def initialize
		super(NAME)
		@linedefs = []
	end
  def read(bytes)
    super(bytes)
    (@bytes.size / BYTES_EACH).times {|index|
      linedef = Linedef.new
      linedef.read(@bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @linedefs << linedef
    }
  end
end

class Linedef
	attr_reader :start_vertex, :end_vertex, :attributes, :special_effects_type, :right_sidedef, :left_sidedef
	def read(bytes)
		@start_vertex = Wad.unmarshal_short(bytes.slice(0,2))
		@end_vertex = Wad.unmarshal_short(bytes.slice(2,2))
		@attributes = Wad.unmarshal_short(bytes.slice(4,2))
		@special_effects_type = Wad.unmarshal_short(bytes.slice(6,2))
		@right_sidedef = Wad.unmarshal_short(bytes.slice(8,2))
		@left_sidedef = Wad.unmarshal_short(bytes.slice(10,2))
	end
	def write
		Wad.marshal_short(@start_vertex) + Wad.marshal_short(@end_vertex) + Wad.marshal_short(@attributes) + Wad.marshal_short(@special_effects_type) + Wad.marshal_short(@right_sidedef) + Wad.marshal_short(@left_sidedef)
	end
	def to_s
		"Linedef from " + @start_vertex.to_s + " to " + @end_vertex.to_s
	end
end

class Thing
  attr_reader :type_id, :location
  attr_accessor :facing_angle
  def read(bytes)
    @location = Point.new(Wad.unmarshal_short(bytes.slice(0,2)), Wad.unmarshal_short(bytes.slice(2,2)))
    @facing_angle = Wad.unmarshal_short(bytes.slice(4,2))
    @type_id = Wad.unmarshal_short(bytes.slice(6,2))
    @flags = Wad.unmarshal_short(bytes.slice(8,2))
  end
	def write
		Wad.marshal_short(@location.x) + Wad.marshal_short(@location.y) + Wad.marshal_short(@facing_angle) + Wad.marshal_short(@type_id) + Wad.marshal_short(@flags)
	end
	def to_s
		Dictionary.get.name_for_type_id(@type_id)	+ " at " + @location.to_s + " facing " + Dictionary.get.direction_for_angle(@facing_angle)
	end
end

class Lumps
	attr_reader :lumps
	def initialize
		@lumps = []
	end
	def add(lump)
		@lumps << lump
	end
	def things
		@lumps.find{|lump| lump.name == Thing.NAME }
		raise "Couldn't find Things lump"
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
		elsif @name == Linedefs::NAME
			lump=Linedefs.new
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
		@lumps = Lumps.new
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
			@lumps.add(de.create_lump(@bytes))
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
		@lumps.lumps.each {|lump|
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
    w.lumps.things.player.facing_angle = 90
  else
    puts "The file " + file + " is a " + w.byte_count.to_s + " byte patch WAD" unless !w.pwad
    puts "It's got " + w.lumps.lumps.size.to_s + " lumps, the directory started at byte " + w.header.directory_offset.to_s
    puts "Lump".ljust(10) + "Size ".ljust(6)
    w.lumps.lumps.each {|lump|
      puts lump.name.ljust(10) + lump.size.to_s.ljust(6)
			if lump.name == "THINGS"
				lump.things.each {|t| puts " - " + t.to_s }
			elsif lump.name == "LINEDEFS"
				lump.linedefs.each {|x| puts " - " + x.to_s }
			end
    }
  end
  w.write("out.wad")
end

