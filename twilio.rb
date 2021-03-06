require 'dotenv/load'

class TwilioService
  def initialize(incomingMessage)
    @client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
    @body = incomingMessage['Body']
    @sender = incomingMessage['From']
    @image = incomingMessage['MediaUrl0']
  end

  def reply(body, image = nil)
    send(sender, body, image)
  end

  def send(to, body, image = nil)
    puts "SENDING"
    puts({ body: body, to: to, from: ENV['TWILIO_PHONE'], image: image })
    return if ENV['DEVELOPMENT']
    begin
      if image
        client.messages.create(
          body: body,
          to: to,
          media_url: [image],
          from: ENV["TWILIO_PHONE"]
        )
      else
        client.messages.create(
          body: body,
          to: to,
          from: ENV["TWILIO_PHONE"]
        )
      end
    rescue Twilio::REST::TwilioError => e
      puts e.message
    end
  end

  def send_to_admins(body)
    User.admins.each { |admin_user| send(admin_user.phone, body) }
  end

  def spam(body, image)
    puts 'sending'
    puts body
    puts image

    User.subscribed.each { |subscribed_user| send(subscribed_user.phone, body, image)}
    send_to_admins("successfully sent out #{User.subscribed.count} messages")
  end

  private

  attr_reader :client, :body, :sender, :image
end