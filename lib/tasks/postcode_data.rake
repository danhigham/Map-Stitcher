require 'csv'
require 'proj4'

namespace :map_stitcher do
  desc "Import csv data"

  task :import_postcode_data  => :environment do
  	data_dir = "/Users/danhigham/Downloads/Code-Point Open/Data"

    Postcode.destroy_all

  	Dir.entries(data_dir).grep(/.csv$/).each { |x| 
  		file_path = "#{data_dir}/#{x}"

  		CSV.foreach(file_path) do |line|
  			postcode = line[0].gsub " ","" 
  			easting = line[2].to_i
  			northing = line[3].to_i

  			srcPoint = Proj4::Point.new(easting, northing)

				srcProj = Proj4::Projection.new('+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs')
				dstProj = Proj4::Projection.new('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')

				dstPoint = srcProj.transform(dstProj, srcPoint)

				lat= dstPoint.lat * (180 / Math::PI)
				lon= dstPoint.lon * (180 / Math::PI)

  			puts "#{postcode} #{lat} #{lon}"

  			Postcode.create :postcode => postcode, :latitude => lat, :longitude => lon
			end


  	}


  end
end