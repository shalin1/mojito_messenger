require 'active_record'

class User < ActiveRecord::Base
  validates :phone, presence: true, uniqueness: true
  before_save { self.name && self.name.downcase!}

  def self.find_by_name_or_phone(query)
    sanitized_query = query.strip.downcase
    strict_name_match = find_by_name(sanitized_query)
    strict_phone_match = find_by_phone(sanitized_query)
    loose_name_match = where("name like ?", "%#{sanitized_query}%")
    loose_number_match = where("phone like ?", "%#{sanitized_query}%")
    res = [ strict_name_match, strict_phone_match ] + loose_name_match + loose_number_match
    res.compact.uniq
  end

  def self.find_by_phone(number)
    self.find_by(phone:E164.normalize(number))
  end

  def admin?
    admin
  end

  def display_name
    name.capitalize
  end

  scope :subscribed, -> { where(subscribed: true) }
  scope :admins, -> { where(admin: true) }
end
