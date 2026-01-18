json.extract! event, :id, :title, :url, :description, :image_url, :start_date, :end_date, :location, :memo, :status, :created_at, :updated_at
json.url event_url(event, format: :json)
