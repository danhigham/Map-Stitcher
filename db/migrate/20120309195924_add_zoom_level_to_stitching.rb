class AddZoomLevelToStitching < ActiveRecord::Migration
  def change
  	add_column :map_stitchings, :zoom_level, :integer
  end
end
