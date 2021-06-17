class User < ActiveRecord::Base
  validates :phone, presence: true

  def admin?
    admin
  end

  scope :subscribed, -> { where(subscribed: true) }
  scope :admins, -> { where(admin: true) }
end
