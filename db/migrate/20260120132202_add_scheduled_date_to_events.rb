class AddScheduledDateToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :scheduled_date, :datetime
  end
end
