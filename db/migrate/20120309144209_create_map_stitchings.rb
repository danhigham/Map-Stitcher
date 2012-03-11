class CreateMapStitchings < ActiveRecord::Migration
  def change
    create_table :map_stitchings do |t|

      t.integer :postcode_id
      t.string :thumbnail_url
      t.string :image_url
      t.string :comment
      
      t.timestamps
    end
  end
end
