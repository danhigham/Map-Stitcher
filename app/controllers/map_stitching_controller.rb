class MapStitchingController < ApplicationController

	def index
		@stitches = MapStitching.where('thumbnail_url is not null').paginate(:page => params[:page], :per_page => 6)
	end

	def new
		@stitching = MapStitching.new
	end

	def create
		# create map stitch record
		@stitching = MapStitching.create(params["map_stitching"])

		# sanitise postcode and assign
		@stitching.postcode_text = @stitching.postcode_text.gsub(" ", "")

		# find postcode
		postcode = Postcode.where(:postcode => @stitching.postcode_text).first

		render 'new.html.erb' if postcode.nil?

		@stitching.postcode = postcode
		@stitching.save!

		# # create delayed job to process
		Delayed::Job.enqueue MapStitchJob.new(@stitching.id)

		redirect_to @stitching
	end

	def update

	end

	def show
		@stitching = MapStitching.find params[:id]
		
	end

end
