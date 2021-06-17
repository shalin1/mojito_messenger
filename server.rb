require 'dotenv/load'
require 'sinatra'
require 'sinatra/activerecord'
require 'twilio-ruby'
require './models'
require './twilio'

post '/sms' do
  twiml = Twilio::TwiML::MessagingResponse.new do |r|
    r.message(body: 'Ahoy! Thanks so much for your message.')
  end

  TwilioService.new.send('+16789367721','hi bud')
  twiml.to_s
end
