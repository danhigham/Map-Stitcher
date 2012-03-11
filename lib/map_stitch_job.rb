
class MapStitchJob < Struct.new(:map_stitch_id)

	include Magick

	ZOOM_STITCH_SIZE_RATIO = 1.0
	TILE_SIZE = 256

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

		(1.upto rows).each do |y|

			(1.upto cols).each do |x|

				tile_no = (cols * (y - 1)) + x 

				quad_key = TileSystem.tile_xy_to_quad_key x + corner_coord_x - 1, y + corner_coord_y - 1, zoom

				download TileSystem.bing_maps_tile_url_for_quad_key(quad_key), "#{temp_path}/#{tile_no}.png"

			end

		end

		join_tiles(cols, rows, temp_path)

		# upload to S3 bucket
		

		# record URL to map_stitch

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

		ilg.append(true).write("#{path}/out.png")

	end

	def download full_url, to_here

    require 'open-uri'

    puts "Downloading #{full_url}"

    writeOut = open(to_here, "wb")
    writeOut.write(open(full_url).read)
    writeOut.close

  end

end