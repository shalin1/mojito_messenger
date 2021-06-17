require 'dotenv/load'
require 'sinatra'
require 'sinatra/activerecord'
require 'twilio-ruby'
require './models'
require './twilio'

use Rack::Session::Cookie, key: 'rack.session',
    path: '/',
    secret: 'can-be-anything-but-keep-a-secret'

post '/sms' do
  sms = TwilioService.new
  message = params
  body = message['Body']
  sender = message['From']

  user = User.find_or_create_by(phone: sender) do
    # block only runs for new user
    session['new_user'] = true
    return sms.send(sender, 'Welcome to Mojito messenger! What is your name?')
  end

  if session['new_user']
    name = body.split(' ').first
    if name
      sms.send(sender, "Sorry, I didn't get that. What's your name?")
    else
      sms.send(sender, "Hi, #{name}!  If you ever want to leave this list, just text STOP.")
      user.update!(name: name, subscribed: true)
      sms.send_to_admins("New subscriber: #{user.name} at #{user.phone}")
      session['new_user'] = false
    end
  elsif user.admin?
    puts session
    puts 'session'
    case
    when session['pending_spam_message']
      if body.downcase.start_with?('hell yeah')
        reply = 'Ok, sending it out!'
        sms.send(sender, reply)
        sms.spam(session['pending_spam_message'])
      else
        reply = 'Spam cancelled, nothing got sent'
        sms.send(sender, reply)
      end
      session['pending_spam_message'] = false
    when body.downcase.start_with?('spam')
      outgoing_message = body.split(' ')[1..-1].join(' ')
      session['pending_spam_message'] = outgoing_message
      reply = "Are you sure you wanna spam the below to #{User.subscribed.count} recipients?  Reply 'hell yeah' to confirm!

----

#{outgoing_message}
"
      sms.send(sender, reply)
    else
      reply = "I didn't get that, #{user.name}! Try again to prefix your message with a command. Valid commands include 'SPAM' and 'SEND'"
      sms.send(sender, reply)
    end
  else
    prefix = "Mojito message from #{user.name} at #{user.number}: "
    sms.send_to_admins(prefix + body)
  end
end