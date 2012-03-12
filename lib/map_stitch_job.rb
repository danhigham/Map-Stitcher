require 'aws/s3'
require 'open-uri'

class MapStitchJob < Struct.new(:map_stitch_id)

	include Magick
	include AWS::S3

	ZOOM_STITCH_SIZE_RATIO = 1.0
	TILE_SIZE = 256
	S3_BUCKET_NAME = 'MAP_STITCHES'

	def perform

		temp_path = Dir.mktmpdir

		# find mapstitch
		stitching = MapStitching.find map_stitch_id

		# position
		lat = stitching.postcode.latitude
		lon = stitching.postcode.longitude
		zoom = stitching.zoom_level

		# get the first tile
		pixel_coords = TileSystem.lat_long_to_pixel_xy lat, lon, zoom

		tile_coords = TileSystem.pixel_xy_to_tile_xy pixel_coords[0], pixel_coords[1]
		
		corner_coord_x = tile_coords[0] - ((ZOOM_STITCH_SIZE_RATIO * zoom) / 2).to_i
		corner_coord_y = tile_coords[1] - ((ZOOM_STITCH_SIZE_RATIO * zoom) / 2).to_i

		corner_coord_x = 0 if corner_coord_x < 0
		corner_coord_y = 0 if corner_coord_y < 0

		cols = rows = (ZOOM_STITCH_SIZE_RATIO * zoom).to_i

		puts "Downloading tiles"

		(1.upto rows).each do |y|

			(1.upto cols).each do |x|

				tile_no = (cols * (y - 1)) + x 

				quad_key = TileSystem.tile_xy_to_quad_key x + corner_coord_x - 1, y + corner_coord_y - 1, zoom

				download TileSystem.bing_maps_tile_url_for_quad_key(quad_key), "#{temp_path}/#{tile_no}.png"

			end

		end

		join_tiles(cols, rows, temp_path)

		puts "Connecting to S3"

		# upload to S3 bucket
		s3_connection = AWS::S3::Base.establish_connection! :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'], :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']

		puts "Uploading thumb to S3"

		# Store the temparary file in s3 bucket
		thumb_guid = UUIDTools::UUID.random_create
		thumb_s3_obj = S3Object.store("#{thumb_guid}.png", open("#{temp_path}/stitch-thumb.png"), S3_BUCKET_NAME, :access => :public_read)

		puts "Uploading main to S3"
		
		main_guid = UUIDTools::UUID.random_create
		main_s3_obj = S3Object.store("#{main_guid}.png", open("#{temp_path}/stitch.jpg"), S3_BUCKET_NAME, :access => :public_read)

		# record URL to map_stitch
		stitching.update_attributes :image_url => S3Object.url_for("#{main_guid}.png", S3_BUCKET_NAME).match(/^.+\.(png|jpg)?/)[0], 
			:thumbnail_url => S3Object.url_for("#{thumb_guid}.png", S3_BUCKET_NAME).match(/^.+\.(png|jpg)?/)[0]

	end

	def join_tiles(cols, rows, path)

		ilg = ImageList.new
		
		1.upto(rows) do |y| 
		
			il = ImageList.new
		
			1.upto(cols) do |x| 

				tile_no = (cols * (y - 1)) + x

				il.push(Image.read("#{path}/#{tile_no}.png").first)
			end

			ilg.push(il.append(false))

		end

		image = ilg.append(true)

		main = image.resize_to_fill(1600, 1600)
		main.write("#{path}/stitch.jpg")

		thumb = image.resize_to_fit(350, 350)
		thumb.write("#{path}/stitch-thumb.png")

	end

	def download full_url, to_here	

    writeOut = open(to_here, "wb")
    writeOut.write(open(full_url).read)
    writeOut.close

  end

end