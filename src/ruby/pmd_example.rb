#!/usr/local/bin/ruby

require "doom.rb"

class PMDMap
MIN = 4
MAX = 10
	def PMDMap.nooks(problems)
	end
	def PMDMap.barrels_per_nook(problems)
	end
end

puts "Counting up the number of problems in the report"
count = 0
File.read("sample_pmd_report.html").each {|line|
	count += 1 if line["</td>"]
}
count = (count/4).to_i

puts "Creating the map"
w = Wad.new(true)
w.lumps << UndecodedLump.new("MAP01")
t = Things.new
t.add_player Point.new(50,900)
w.lumps << t

puts "Putting together a suitable path"
p = Path.new(0, 1000)
p.add("e200/n200/e200/s200/e200/", PMDMap.nooks(count/2))
p.add("s400/")
p.add("w200/s200/w200/n200/w200/", PMDMap.nooks(count/2))
p.add("n400/")

puts "Placing the barrels"


w.lumps << p.vertexes
w.lumps << p.sectors
w.lumps << p.sidedefs
w.lumps << p.linedefs

puts "Writing the map to disk"
w.write("new.wad")

if ARGV.include?("-nethack")
  puts p.nethack
  puts "Map generated from " + p.to_s
end


