require 'dotenv/load'

class TwilioService
  def initialize
    @client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
  end

  def send(to, body)
    begin
      client.messages.create(
        body: body,
        to: to,
        from: '+19412137305'
      )
    rescue Twilio::REST::TwilioError => e
      puts e.message
    end
  end

  def send_to_admins(body)
    User.admins.each { |admin_user| send(admin_user.phone, body) }
  end

  def spam(body)
    User.subscribed.each { |subscribed_user| send(subscribed_user.phone, body)}
  end

  private

  attr_reader :client
end