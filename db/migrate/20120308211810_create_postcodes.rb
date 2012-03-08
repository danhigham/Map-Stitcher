class CreatePostcodes < ActiveRecord::Migration
  def change
    create_table :postcodes do |t|
      t.string  :postcode
      t.float   :latitude
      t.float   :longitude

      t.timestamps
    end

    add_index :postcodes, [:latitude, :longitude]
  end
end
