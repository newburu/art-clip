class Event < ApplicationRecord
  belongs_to :user
  enum :status, { interested: 0, going: 1, went: 2 }, default: :interested

  validates :title, presence: true
  validates :url, presence: true
end
