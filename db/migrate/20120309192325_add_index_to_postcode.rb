class AddIndexToPostcode < ActiveRecord::Migration
  def change
  	add_index :postcodes, [:postcode]
  end
end
