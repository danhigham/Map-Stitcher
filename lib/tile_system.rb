# Ruby version of TileSystem class at http://msdn.microsoft.com/en-us/library/bb259689.aspx

class TileSystem

	EARTH_RADIUS = 6378137
	MIN_LATITUDE = -85.05112878
	MAX_LATITUDE = 85.05112878
	MIN_LONGITUDE = -180
	MAX_LONGITUDE = 180

	def self.clip(n, min_value, max_value)
		[[n, min_value].max, max_value].min
	end

	def self.map_size(detail_level)
		256 << detail_level
	end

	def self.ground_resolution(latitude, detail_level)
		latitude = clip latitude, MIN_LATITUDE, MAX_LATITUDE
		Math.cos(latitude * Math::PI / 180) * 2 * Math::PI * EARTH_RADIUS / map_size(detail_level)
	end

	def self.map_scale(latitude, detail_level, screen_dpi)
		ground_resolution(latitude, detail_level) * screen_dpi / 0.0254
	end

	def self.lat_long_to_pixel_xy(latitude, longtitude, detail_level)
		latitude = clip latitude, MIN_LATITUDE, MAX_LATITUDE
		longtitude = clip longtitude, MIN_LONGITUDE, MAX_LONGITUDE

		x = (longtitude + 180) / 360
		sin_latitude = Math.sin(latitude * Math::PI / 180)
		y = 0.5 - Math.log((1 + sin_latitude) / (1 - sin_latitude)) / (4 * Math::PI)

		map_size = map_size(detail_level).to_i
		pixel_x = clip(x * map_size + 0.5, 0, map_size - 1).to_i
		pixel_y = clip(y * map_size + 0.5, 0, map_size - 1).to_i
		[pixel_x, pixel_y]
	end

	def self.pixel_xy_to_lat_long(pixel_x, pixel_y, detail_level)
		map_size = map_size detail_level
		x = (clip(pixel_x, 0, map_size - 1) / map_size) - 0.5
		y = 0.5 - (clip(pixel_y, 0, map_size - 1) / map_size)

		latitude = 90 - 360 * Math.atan(Math.exp(-y * 2 * Math::PI)) / Math::PI
		longtitude = 360 * x
	end

	def self.pixel_xy_to_tile_xy(pixel_x, pixel_y)
		[(pixel_x / 256).to_i, (pixel_y / 256).to_i]
	end

	def self.tile_xy_to_pixel_xy(tile_x, tile_y)
		[tile_x * 256, tile_y * 256]
	end

	def self.tile_xy_to_quad_key(tile_x, tile_y, detail_level)
		quad_key = ''

		(detail_level.downto 1).each do |i|
			digit = 0
			mask = 1 << (i - 1)
			digit += 1 if (tile_x & mask) != 0
			digit += 2 if (tile_y & mask) != 0
			quad_key << digit.to_s
		end

		quad_key
	end

	def self.quad_key_to_tile_x_y(quad_key)
		tile_x = tile_y = 0;
		detail_level = quad_key.length

		(detail_level.downto 1).each do |i|
			mask = 1 << (i - 1)
				
			case quad_key[detail_level - i]
			when '0'

			when '1'
				tile_x |= mask
			when '2'
				tile_y |= mask
			when '3'
				tile_x |= mask
				tile_y |= mask
			else
				raise "Invalid QuadKey digit sequence"
			end
		end

		[tile_x, tile_y]
	end
	
	def self.google_maps_tile_url_for_quad_key(quad_key)

	end

	def self.bing_maps_tile_url_for_quad_key(quad_key)
		# sample url for tile :- 
		# http://ecn.t0.tiles.virtualearth.net/tiles/r120300?g=886&mkt=en-gb&lbl=l1&stl=h&shading=hill&n=z

		# normal
		# "http://ecn.t0.tiles.virtualearth.net/tiles/r#{quad_key}?g=886&mkt=en-gb&lbl=l1&stl=h&shading=hill&n=z"

		# aerial
		"http://ecn.t0.tiles.virtualearth.net/tiles/a#{quad_key}.jpeg?g=886&mkt=en-gb&n=z"

		# composition
		# "http://ecn.dynamic.t3.tiles.virtualearth.net/comp/CompositionHandler/#{quad_key}?mkt=en-gb&it=A,G,L&n=z"
	end
end

