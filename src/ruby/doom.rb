#!/usr/local/bin/ruby

# s - short
# l - long
# 4 - 4 byte string
# 8 - 8 bytes string
class Codec
	# Accepts a format string like "sl48" and a byte array
	def Codec.decode(format, bytes)
		res = []
		ptr = 0
		format.split(//).each {|x|
			if x == "s"
				res << Codec.unmarshal_short(bytes.slice(ptr,2))
				ptr += 2
			elsif x == "l"	
				res << Codec.unmarshal_long(bytes.slice(ptr,4))
				ptr += 4
			elsif x == "4"
				res << Codec.unmarshal_string(bytes.slice(ptr,4))
				ptr += 4
			elsif x == "8"
				res << Codec.unmarshal_string(bytes.slice(ptr,8))
				ptr += 8
			else
				raise "Unknown character in decode format string " + format
			end
		}
		return res
	end
	# Accepts a format string like "sl48" and an array of values 
	def Codec.encode(format, values)
		bytes = []	
		ptr = 0
		format.split(//).each {|x|
			if x == "s"
				bytes += Codec.marshal_short(values[ptr])
			elsif x == "l"	
				bytes += Codec.marshal_long(values[ptr])
			elsif x == "4"
				bytes += Codec.marshal_string(values[ptr],4)
			elsif x == "8"
				bytes += Codec.marshal_string(values[ptr],8)
			else
				raise "Unknown character in decode format string " + format
			end
			ptr += 1
		}
		return bytes
	end
	def Codec.unmarshal_long(a)
		a.pack("C4").unpack("V")[0]
	end
	def Codec.marshal_long(n)
		[n].pack("N").unpack("C4").reverse
	end
	def Codec.unmarshal_short(a)
		a.reverse.pack("C2").unpack("n")[0]
	end
	def Codec.marshal_short(s)
		[s].pack("n").unpack("C2").reverse
	end
	def Codec.unmarshal_string(a)
		a.pack("C*").strip
	end
	def Codec.marshal_string(n,len)
		arr = n.unpack("C#{len}").compact
		if arr.size < len
			arr += Array.new(len-arr.size, 0)
		end
		arr
	end
end

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
  BYTES_EACH=14
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
	def write
		out = []
		@linedefs.each {|t| out += t.write }
		out
	end
end

class Linedef
	attr_reader :start_vertex, :end_vertex, :attributes, :special_effects_type, :right_sidedef, :left_sidedef
	def read(bytes)
		@start_vertex, @end_vertex, @attributes, @special_effects_type, @tag, @right_sidedef, @left_sidedef = Codec.decode("sssssss", bytes)
	end
	def write
		Codec.encode("sssssss", [@start_vertex, @end_vertex, @attributes, @special_effects_type, @tag, @right_sidedef, @left_sidedef])
	end
	def to_s
		"Linedef from " + @start_vertex.to_s + " to " + @end_vertex.to_s + "; attribute flag is " + @attributes.to_s + "; special fx is " + @special_effects_type.to_s + "; tag is " + @tag.to_s + "; right sidedef is " + @right_sidedef.to_s + "; left sidedef is " + @left_sidedef.to_s
	end
end

class Thing
  attr_reader :type_id, :location
  attr_accessor :facing_angle
  def read(bytes)
		x, y, @facing_angle, @type_id, @flags = Codec.decode("sssss", bytes)
		@location = Point.new(x,y)
  end
	def write
		Codec.encode("sssss", [@location.x, @location.y, @facing_angle, @type_id, @flags])
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
	BYTES_EACH=16
	attr_accessor :offset, :size, :name
	def initialize(offset=nil,size=nil,name=nil)
		@offset = offset
		@size = size
		@name = name
	end
	def read(array)
			@offset, @size, @name = Codec.decode("ll8", array)
	end
	def write
		Codec.encode("ll8", [@offset, @size, @name])
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
	BYTES_EACH=12
	attr_reader :type, :lump_count
	attr_accessor :directory_offset
	def read(array)
		@type, @lump_count, @directory_offset = Codec.decode("4ll", array)
	end
	def write
		Codec.encode("4ll", [@type, @lump_count, @directory_offset])
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
		@header.read(@bytes.slice(0,Header::BYTES_EACH))
		@header.lump_count.times {|directory_entry_index|
			de = DirectoryEntry.new
			de.read(@bytes.slice((directory_entry_index*DirectoryEntry::BYTES_EACH)+@header.directory_offset,DirectoryEntry::BYTES_EACH))
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
		ptr = Header::BYTES_EACH
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

