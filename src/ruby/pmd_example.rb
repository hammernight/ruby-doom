#!/usr/local/bin/ruby

require "doom.rb"

class PMDMap
MIN_NOOKS = 2
MAX_NOOKS = 12
	def initialize(problems)
		@problems = problems
	end
	def nooks()
		if @problems < MIN_NOOKS
			return MIN_NOOKS
		elsif @problems > 100
			return MAX_NOOKS
		end
		return (@problems/10).to_i + MIN_NOOKS
		
	end
end

puts "Counting up the number of problems in the report"
count = 0
File.read("sample_pmd_report.html").each {|line|
	count += 1 if line["</td>"]
}
count = (count/4).to_i

pmd = PMDMap.new(count)

puts "Creating the map"
w = Wad.new(true)
w.lumps << UndecodedLump.new("MAP01")
t = Things.new
t.add_player Point.new(50,900)
w.lumps << t

puts "Putting together a suitable path"
p = Path.new(0, 1000)
p.add("e200/n200/e200/s200/e200/", pmd.nooks)
p.add("s400/")
p.add("w200/s200/w200/n200/w200/", pmd.nooks)
p.add("n400/")

puts "Placing the barrels"
1.upto(pmd.nooks) {|x|
	t.add_barrel Point.new(x*300, 1050)
	t.add_barrel Point.new(x*300, 950)
}


puts "Assembling the rest of the map"
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

