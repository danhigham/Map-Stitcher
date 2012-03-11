class MapStitching < ActiveRecord::Base
	attr_accessor :postcode_text
	
	belongs_to :postcode
end
