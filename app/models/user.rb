class User < ApplicationRecord
  has_many :events, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = auth.info.name
      user.email = auth.info.email
      user.image = auth.info.image
    end
  end
  def self.guest
    find_or_create_by!(email: "guest@example.com") do |user|
      user.name = "ゲストユーザー"
      user.provider = "guest"
      user.uid = "guest_uid"
      user.image = "/icon.png"
    end
  end
end
