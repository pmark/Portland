if ARGV.length < 2
  puts "\n\nUSAGE: ruby #{$0} couch_url path_to_asc_data_file [start_row] [end_row]\n\n\n"
  exit
end


require "rubygems"
require "couchrest"
require "date"

#Set database

couch_url = ARGV.first
@db = CouchRest.database!(couch_url)


def post(batch)
  puts "."
  @db.bulk_save(batch)
end


#Set source file to srtm
file_path = ARGV[1]
srtm = File.open(file_path)

#Extract values from header constants

ncols = srtm.readline.sub("ncols", "").sub("\n", "").gsub(/\s/, "").to_i
nrows = srtm.readline.sub("nrows", "").sub("\n", "").gsub(/\s/, "").to_i
xllcorner = srtm.readline.sub("xllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
yllcorner = srtm.readline.sub("yllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
cellsize = srtm.readline.sub("cellsize", "").sub("\n", "").gsub(/\s/, "").to_f
NODATA_value = srtm.readline.sub("NODATA_value", "").sub("\n", "").gsub(/\s/, "").to_f

#Convert elevation values string to gridline array

celly = 0
batch_size = 1000
start_time = DateTime.now
start_row = ARGV[2].to_i || 0
end_row = ARGV[3].to_i || nrows

puts "\nImporting #{end_row - start_row} rows from '#{file_path}' into '#{couch_url}'\n\n"

(0..nrows).each do |i|

  break if srtm.eof?

  gridline = srtm.readline

  if (i < start_row) 
    next
  elsif (i > end_row)
    break
  end

  gridline = gridline.split.collect { |e| e.to_i }

  #Get array position

  cellx = 0
  celly = i

  #Populate passthrough array with processing point

  lat = yllcorner + cellsize * celly
  batch = []

  # parse one line
  gridline.collect do |elev| 

    elev = '' if (elev == -9999)

    long = xllcorner+cellsize*cellx

    # create the document
    one_document = { :elev => elev, :geometry => { :type => 'Point', :coordinates => [long, lat] } }

    # Should the batch be submitted yet?        
    if (cellx > 0 && cellx % batch_size == 0)
      post(batch)
      batch = [one_document]

    elsif cellx == (ncols - 1)
      # on last column
      batch << one_document
      post(batch)

    else
      batch << one_document
    end

    cellx += 1

    # break if cellx > 9
  end

  puts "row #{i}" if (i % 1) == 0
end


stop_time = DateTime.now
run_time = ((stop_time - start_time) * 24 * 60 * 60).to_f

puts "\nImported #{end_row - start_row} rows in #{run_time} sec.\n\n"


# Add design doc if necessary

def add_ddoc

  ddoc_name = '_design/lon_lat_elev'

  view_exists = @db.get(ddoc_name) rescue false


  unless view_exists

    puts "Adding spatial lon_lat_elev index design document.\n\n"

    @db.save_doc({
        "_id" => ddoc_name,
        "spatial" => {
            "points" => "function(doc) { emit(doc.geometry, doc.elev); }"
        }
      })
  end
  
end

add_ddoc

