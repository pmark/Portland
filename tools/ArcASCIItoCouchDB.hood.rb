require "rubygems"
require "couchrest"
require "date"

#Set database

# @db = CouchRest.database!("http://pmark.couchone.com/elevation_pacnw")
@db = CouchRest.database!("http://127.0.0.1:5984/elevation_hood122")


def post(batch)
  puts "submitting batch"
  @db.bulk_save(batch)
end

Dir.chdir("/")

#Set source file to srtm

srtm = File.open("hood122.txt")

#Extract values from header constants

ncols = srtm.readline.sub("ncols", "").sub("\n", "").gsub(/\s/, "").to_f
nrows = srtm.readline.sub("nrows", "").sub("\n", "").gsub(/\s/, "").to_f
xllcorner = srtm.readline.sub("xllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
yllcorner = srtm.readline.sub("yllcorner", "").sub("\n", "").gsub(/\s/, "").to_f
cellsize = srtm.readline.sub("cellsize", "").sub("\n", "").gsub(/\s/, "").to_f
NODATA_value = srtm.readline.sub("NODATA_value", "").sub("\n", "").gsub(/\s/, "").to_f

#Convert elevation values string to gridline array

celly = 0
batch_size = 1000
number_of_records_to_skip = 0  # make this 4200 for pacnw

start_time = DateTime.now

(0..nrows).each do |i|

  break if srtm.eof?

  gridline = srtm.readline


  if (i >= number_of_records_to_skip) 

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
end

stop_time = DateTime.now
run_time = ((stop_time - start_time) * 24 * 60 * 60).to_f

puts "\n  Imported #{celly + 1 - number_of_records_to_skip} rows in #{run_time} sec\n"
