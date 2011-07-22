Dir.chdir("/Users/ethomasburke/Projects/Hood/tools/cgiar")

#Open ArcASCII file

arc = File.open("obds.asc")

#Extract values from header constants

ncols = arc.readline.sub("ncols", "").sub("\n", "").gsub(/\s/, "").to_i
nrows = arc.readline.sub("nrows", "").sub("\n", "").gsub(/\s/, "").to_i
xllcorner = arc.readline.sub("xllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
yllcorner = arc.readline.sub("yllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
cellsize = arc.readline.sub("cellsize", "").sub("\n", "").gsub(/\s/, "").to_f
NODATA_value = arc.readline.sub("NODATA_value", "").sub("\n", "").gsub(/\s/, "").to_f

puts cellsize

earthradius = 6371000
latitude = yllcorner * (Math::PI / 180)

xpoint_spacing = (2 * Math::PI * (earthradius * Math.cos(latitude))) * (cellsize / 360)
ypoint_spacing = cellsize / 360 * (2 * Math::PI * earthradius)

puts xpoint_spacing
puts ypoint_spacing

#Put origin lat/lon in header

header = Array.new

header << "# #{xllcorner}, #{yllcorner}"

arcobj = File.open("obds.obj","a") do |f1|

  f1.puts header

end

#Create empty pass through array

pass_through = Array.new

#Populate array with elevation data from ArcASCII file

until arc.eof?

  gridline = arc.readline.each { |e| e.to_i }

  pass_through << gridline

end

#Flip it so we can populate the OBJ in the proper order

pass_through.reverse!

arc.close

#Break the array into individual points

pass_through.flatten!

#Create the empty arrays for point processing

one_point = Array.new

v_values = Array.new

v_array = Array.new

pass_through_line = Array.new

#Initiate the y origin

celly = 0

#Create the verticies

until celly == nrows

  cellx = 0

  until cellx >= ncols

    pass_through_line = pass_through.at(celly).split

    one_point << "v"

    one_point << cellx * xpoint_spacing

    one_point << celly * ypoint_spacing

    one_point << pass_through_line.at(cellx)

    v_array << one_point

    v_values << v_array.join(" ")

    v_array.clear

    one_point.clear

    cellx += 1

    latitude = (yllcorner + cellsize) * (Math::PI / 180)

    xpoint_spacing = (2 * Math::PI * (earthradius * Math.cos(latitude))) * (cellsize / 360)

  end

  celly += 1

  puts celly

end

puts "added #{v_values.count} v values"

#Put those verticies into the new OBJ file

arcobj = File.open("obds.obj","a") do |f1|

  f1.puts v_values

end

#Create empty f values array

vertex_connect = Array.new

vertex_connect_point = Array.new

#Initiate the origins

line = 0

position = 1

#Populate the f values

until line == nrows - 1

  #Starting at SW point, populate f value array

  until position == (ncols * (line + 1))

    vertex_connect_point << "f"

    vertex_connect_point << position

    vertex_connect_point << position + 1

    vertex_connect_point << position + ncols + 1

    vertex_connect_point << position + ncols

    vertex_connect << vertex_connect_point.join(" ")

    vertex_connect_point.clear

    position += 1

  end

  position += 1

  line += 1

  puts line

end

puts "added #{vertex_connect.count} f values"

#Populate OBJ with f values

arcobj = File.open("obds.obj","a") do |f1|

    f1.puts vertex_connect

end