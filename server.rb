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
  body = params['Body']
  sender = params['From']
  image = params['MediaUrl0']

  user = User.find_or_create_by(phone: sender)
  if !user.admin?
    if user.subscribed
      if body.downcase.start_with?('stop')||body.downcase.start_with?('cancel')
        user.update!(subscribed:false)
        sms.send(sender, "You've been unsubscribed. To get back on the list, just text in with your password.")
        admin_prefix = "#{user.name} [#{user.phone}] left the list with this message: "
        sms.send_to_admins(admin_prefix + body)
      else
      reply_prefix = user.name.blank? ? "" : "Welcome back, #{user.name}"
      sms.send(sender, reply_prefix + "Our mojito bots are reviewing your message, and will reply within 2 business days.")
      admin_prefix = "Mojito message from #{user.name} [#{user.phone}]: "
      sms.send_to_admins(admin_prefix + body)
      end
    else
      if body.downcase.include?('mojito')
        user.update!(subscribed:true)
        sms.send(sender, 'Congrats! You are now subscribed to the Mojito Messenger mailing list! Please reply with your name to finish sign up. And if you ever wanna leave the list, just text STOP.')
        sms.send_to_admins("New sign up from phone number #{sender}!")
      else
       sms.send(sender, 'A mysterious door opens before you. What is the password?')
       admin_prefix = "Mojito message from unsubscribed user at [#{user.phone}]: "
       sms.send_to_admins(admin_prefix + body)
      end
    end
  end

  case
  when session['pending_spam_message']
    if body.downcase.start_with?('hell yeah')
      reply = 'Ok, sending it out!'
      sms.send(sender, reply)
      sms.spam(session['pending_spam_message'], session['pending_spam_image'])
    else
      reply = 'Spam cancelled, nothing got sent'
      sms.send(sender, reply)
    end
    session['pending_spam_message'] = false
    session['pending_spam_image'] = false
  when body.downcase.start_with?('spam')
    outgoing_message = body.split(' ')[1..-1].join(' ')
    session['pending_spam_message'] = outgoing_message
    session['pending_spam_image'] = image

    reply = "Are you sure you wanna spam the below to #{User.subscribed.count} recipients?  It will cost around $#{(User.subscribed.count / 30.0).round(2) }.  Reply 'hell yeah' to confirm!

----

#{outgoing_message}
    "
    sms.send(sender, reply, image)
  else
    reply = "I didn't get that, #{user.name}! Try again to prefix your message with a command. Valid commands include 'SPAM' and 'SEND'"
    sms.send(sender, reply)
  end
end