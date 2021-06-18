require 'dotenv/load'

class TwilioService
  def initialize
    @client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
  end

  def send(to, body, image = nil)
    if ENV['DEVELOPMENT']
      puts "SENDING"
      puts({ body: body, to: to, from: '+19412137305' })
    else
      begin
        client.messages.create(
          body: body,
          to: to,
          media_url: [image],
          from: '+19412137305'
        )
      rescue Twilio::REST::TwilioError => e
        puts e.message
      end
    end
  end

  def send_to_admins(body)
    User.admins.each { |admin_user| send(admin_user.phone, body) }
  end

  def spam(body,image)
    User.subscribed.each { |subscribed_user| send(subscribed_user.phone, body, image)}
  end

  private

  attr_reader :client
end