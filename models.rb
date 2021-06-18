require 'active_record'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

class User < ActiveRecord::Base
  validates :phone, presence: true

  def admin?
    admin
  end

  scope :subscribed, -> { where(subscribed: true) }
  scope :admins, -> { where(admin: true) }
end
