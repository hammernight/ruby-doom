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
		#a.reverse.pack("C2").unpack("n")[0]
		a.pack("c2").unpack("s")[0]
	end
	def Codec.marshal_short(s)
		#[s].pack("n").unpack("C2").reverse
		[s].pack("S").unpack("C2")
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
		"(" + @x.to_s + "," + @y.to_s + ")"
	end
end

class Lump
	attr_reader :name
	def initialize(name)
		@name = name
	end
end

class DecodedLump < Lump
	attr_reader :items
	def initialize(name)
		super(name)
		@items = []
	end
	def add(i)
		@items << i
	end
	def write
		out = []
		@items.each {|s| out += s.write }
		out
	end
end

class UndecodedLump < Lump
	def read(bytes)
		@bytes = bytes
	end
	def write
		@bytes
	end
	def size
		@bytes.size
	end
	def items
		[]
	end
end

class Sectors < DecodedLump
	BYTES_EACH=26
	NAME="SECTORS"
	attr_accessor :id
  def initialize
    super(NAME)
		@index = 0
  end
	def add(i)
		i.id = @index
		@index += 1
		super(i)
	end
  def read(bytes)
    (bytes.size / BYTES_EACH).times {|index|
      s = Sector.new
      s.read(bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @items << s
    }
  end
	def size
		@items.size * BYTES_EACH
	end
end

class Sector
	FORMAT="ss88sss"
	attr_accessor :floor_height, :ceiling_height, :floor_texture, :ceiling_texture, :light_level, :special, :tag, :id
	def initialize
		@floor_height=0
		@ceiling_height=128
		@floor_texture="FLAT14"
		@ceiling_texture="FLAT14"
		@light_level=255
		@special=0
		@tag=0
	end
  def read(bytes)
		@floor_height, @ceiling_height, @floor_texture, @ceiling_texture, @light_level, @special, @tag = Codec.decode(FORMAT, bytes)
  end
	def write
		Codec.encode(FORMAT, [@floor_height, @ceiling_height, @floor_texture, @ceiling_texture, @light_level, @special, @tag])
	end
	def to_s
		" Sector floor/ceiling heights " + @floor_height.to_s + "/" + @ceiling_height.to_s + "; floor/ceiling textures " + @floor_texture.to_s + "/" + @ceiling_textures.to_s
	end
end

class Vertexes < DecodedLump
	BYTES_EACH=4
	NAME="VERTEXES"
  def initialize
    super(NAME)
		@index = 0
  end
  def read(bytes)
    (bytes.size / BYTES_EACH).times {|index|
      v = Vertex.new
      v.read(bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @items << v
    }
  end
	def add(i)
		i.id = @index
		@index += 1
		super(i)
	end
	def size
		@items.size * BYTES_EACH
	end
end

class Vertex
	FORMAT="ss"
	attr_reader :location 
	attr_accessor :id
	def initialize(location=nil)
		@location = location
	end	
  def read(bytes)
		@location = Point.new(*Codec.decode(FORMAT, bytes))
  end
	def write
		Codec.encode(FORMAT, [@location.x, @location.y])
	end
	def to_s
		" Vertex at " + @location.to_s
	end
end

class Sidedefs < DecodedLump
	BYTES_EACH=30
  NAME="SIDEDEFS"
  def initialize
    super(NAME)
  end
  def read(bytes)
    (bytes.size / BYTES_EACH).times {|index|
      s = Sidedef.new
      s.read(bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @items << s
    }
  end
	def size
		@items.size * BYTES_EACH
	end
end

class Sidedef
	FORMAT="ss888s"
  def read(bytes)
		@x_offset, @y_offset, @upper_texture, @lower_texture, @middle_texture, @sector_id = Codec.decode(FORMAT, bytes)
  end
	def write
		Codec.encode(FORMAT, [@x_offset, @y_offset, @upper_texture, @lower_texture, @middle_texture, @sector_id])
	end
	def to_s
		" Sidedef for sector " + @sector_id.to_s
	end
end

class Things < DecodedLump
  BYTES_EACH=10
  NAME="THINGS"
  def initialize
    super(NAME)
  end
  def read(bytes)
    (bytes.size / BYTES_EACH).times {|index|
      thing = Thing.new
      thing.read(bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @items << thing
    }
  end
	def size
		@items.size * BYTES_EACH
	end
	def player
		@items.find {|t| t.type_id == 1 } 
		raise "Couldn't find player Thing"
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


class Linedefs < DecodedLump
  BYTES_EACH=14
	NAME="LINEDEFS"
	def initialize
		super(NAME)
	end
  def read(bytes)
    (bytes.size / BYTES_EACH).times {|index|
      linedef = Linedef.new
      linedef.read(bytes.slice(index*BYTES_EACH, BYTES_EACH))
      @items << linedef
    }
  end
	def size
		@items.size * BYTES_EACH
	end
end

class Linedef
	FORMAT="sssssss"
	attr_reader :start_vertex, :end_vertex, :attributes, :special_effects_type, :right_sidedef, :left_sidedef
	def read(bytes)
		@start_vertex, @end_vertex, @attributes, @special_effects_type, @tag, @right_sidedef, @left_sidedef = Codec.decode(FORMAT, bytes)
	end
	def write
		Codec.encode(FORMAT, [@start_vertex, @end_vertex, @attributes, @special_effects_type, @tag, @right_sidedef, @left_sidedef])
	end
	def to_s
		"Linedef from " + @start_vertex.to_s + " to " + @end_vertex.to_s + "; attribute flag is " + @attributes.to_s + "; special fx is " + @special_effects_type.to_s + "; tag is " + @tag.to_s + "; right sidedef is " + @right_sidedef.to_s + "; left sidedef is " + @left_sidedef.to_s
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
		elsif @name == Sidedefs::NAME
			lump=Sidedefs.new
		elsif @name == Vertexes::NAME
			lump=Vertexes.new
		elsif @name == Sectors::NAME
			lump=Sectors.new
		else
			lump=UndecodedLump.new(@name)
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
		File.new(filename).each_byte {|b| 
			@bytes << b 
			puts "Read " + (@bytes.size/1000).to_s + " KB so far " unless (!@verbose or @bytes.size % 500000 != 0)
		}
		puts "Done reading, building the object model" unless !@verbose
		@header = Header.new
		@header.read(@bytes.slice(0,Header::BYTES_EACH))
		@header.lump_count.times {|directory_entry_index|
			de = DirectoryEntry.new
			de.read(@bytes.slice((directory_entry_index*DirectoryEntry::BYTES_EACH)+@header.directory_offset,DirectoryEntry::BYTES_EACH))
			lump = de.create_lump(@bytes)
			puts "Created " + lump.name unless !@verbose
			@lumps.add(lump)
		}
		puts "Object model built" unless !@verbose
    puts "The file " + filename + " is a " + @bytes.size.to_s + " byte " + @header.type unless !@verbose
    puts "It's got " + @lumps.lumps.size.to_s + " lumps, the directory started at byte " + @header.directory_offset.to_s unless !@verbose
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
  if ARGV.include?("-turn")
 		 file = ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
	  w = Wad.new(ARGV.include?("-v"))
	  w.read(file)
    w.lumps.things.player.facing_angle = 90
  	w.write("out.wad")
  elsif ARGV.include?("-create")
		puts "Creating a nice, simple, square using counterclockwise linedefs from 64,-512 to 128,-320"
		w = Wad.new(true)
	
		v = Vertexes.new
		v1 = v.add Vertex.new(Point.new(64,-512))
		v2 = v.add Vertex.new(Point.new(128,-512))
		v3 = v.add Vertex.new(Point.new(128,-320))
		v4 = v.add Vertex.new(Point.new(64, -320))

		sectors = Sectors.new
		s1 = sectors.add Sector.new

		#sidedefs = Sidedefs.new
		#sidedefs.add Sidedef.new

		#linedefs = Linedefs.new
		#linedefs.add Linedef.new(v1,v2)

		#w.write("out.wad")
		exit
	else
  	file = ARGV.include?("-f") ? ARGV[ARGV.index("-f") + 1] : "../../test_wads/simple.wad"
	  w = Wad.new(ARGV.include?("-v"))
	  w.read(file)
    w.lumps.lumps.each {|lump|
      puts lump.name + " (" + lump.size.to_s + " bytes)"
			lump.items.each {
				|t| puts " - " + t.to_s 
			}
    }
  	w.write("out.wad")
  end
end

