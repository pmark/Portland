Dir.chdir("/Users/ethomasburke/Projects/Hood/tools/cgiar")

arc = File.open("utmhoodsp.asc")
ncols = arc.readline.sub("ncols", "").sub("\n", "").gsub(/\s/, "").to_i
nrows = arc.readline.sub("nrows", "").sub("\n", "").gsub(/\s/, "").to_i
xllcorner = arc.readline.sub("xllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
yllcorner = arc.readline.sub("yllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
cellsize = arc.readline.sub("cellsize", "").sub("\n", "").gsub(/\s/, "").to_f
NODATA_value = arc.readline.sub("NODATA_value", "").sub("\n", "").gsub(/\s/, "").to_f

#Origins are always at the bottom FUCKING left
#What's your bounding box?

lat_bound = 45.278439
long_bound = -121.816742
bound_length = 600

puts yllcorner
puts xllcorner
puts cellsize

#Set are the row/column coordinates

col_bound = xllcorner.abs - long_bound.abs
row_bound = lat_bound.abs - yllcorner.abs

puts col_bound
puts row_bound

col_bound = (col_bound / cellsize).to_i
row_bound = (row_bound / cellsize).to_i

puts col_bound
puts row_bound

#Calculate the snapped lat,long - Make new file represent values at the center of the cells

snapped_bound_long = (xllcorner + ((col_bound - 1) * cellsize))
snapped_bound_lat = (yllcorner + ((row_bound - 1) * cellsize))

puts snapped_bound_long
puts snapped_bound_lat

#Jump row and column bounds to ArcASCii locations

row_bound = nrows - row_bound + 6

#Create a passthrough array

new_arc = Array.new

#Jump to the first row line

until $. > row_bound - bound_length

  arc.readline
  
end

#Populate the passthrough array with data

until $.-1 >= row_bound

  gridline = arc.readline.split.each { |e| e.to_i }

  bounded = gridline[col_bound...(col_bound+bound_length)].join(" ")

  new_arc << bounded

end

arc.close

puts "#{new_arc.count} values added to passthrough array"

#Write new header info to new_arc_file

new_arc_file =  File.open("new_arc.asc", "a") do |f1|
  
  f1.puts "ncols #{bound_length}\r\nnrows #{bound_length}\r\nxllcorner #{snapped_bound_long}\r\nyllcorner #{snapped_bound_lat}\r\ncellsize #{cellsize}\r\nNODATA_value #{NODATA_value}\r\n"
  
end

#Write elevation values to new_arc_file

new_arc_file = File.open("new_arc.asc", "a") do |f2|

f2.puts new_arc

end