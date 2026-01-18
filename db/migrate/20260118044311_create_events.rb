class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title
      t.text :url
      t.text :description
      t.string :image_url
      t.datetime :start_date
      t.datetime :end_date
      t.string :location
      t.text :memo
      t.integer :status

      t.timestamps
    end
  end
end
