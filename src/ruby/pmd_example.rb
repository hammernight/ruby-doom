#!/usr/local/bin/ruby

require "doom.rb"

class PMDMap
MIN_NOOKS = 2
MAX_NOOKS = 12
	def initialize(filename)
		count = 0
		File.read(filename).each {|line| count += 1 if line["</td>"] }
		@problems = count == 0 ? 0 : (count/4).to_i
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
pmd = PMDMap.new("sample_pmd_report.html")

puts "Creating the map"
p = Path.new(0, 1000)
p.add("e200/n200/e200/s200/e200/", pmd.nooks)
p.add("s400/")
p.add("w200/s200/w200/n200/w200/", pmd.nooks)
p.add("n400/")

m = SimpleLineMap(p)
m.set_player(Point.new(50,900))
0.upto(pmd.nooks-1) {|x|
	m.add_barrel Point.new((x*600)+300, 1100)
	m.add_barrel Point.new((x*600)+300, 500)
}
m.create_wad("new.wad")

if ARGV.include?("-nethack")
  puts p.nethack(50)
  puts "Map generated from " + p.to_s
end
