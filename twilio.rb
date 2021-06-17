class TwilioService
  def initialize
    @client = Twilio::REST::Client.new(ENV['ACCOUNT_SID'], ENV['AUTH_TOKEN'])
  end

  def send(to, body)
    client.messages.create(
      from: ENV['TWILIO_PHONE'],
      to: to,
      body: body
    )
  end

  private

  attr_reader :client
end