require 'dotenv/load'
require 'e164'
require 'sinatra'
require 'sinatra/activerecord'
require 'twilio-ruby'
require './models'
require './twilio'

use Rack::Session::Cookie, key: 'rack.session',
    path: '/',
    secret: 'can-be-anything-but-keep-a-secret'

post '/sms' do
  sms = TwilioService.new(params)
  body = params['Body']
  sender = params['From']
  image = params['MediaUrl0']

  user = User.find_or_create_by(phone: sender)
  if !user.admin?
    if user.subscribed
      if body.downcase.start_with?('stop')||body.downcase.start_with?('cancel')
        user.update!(subscribed:false)
        sms.reply("You've been unsubscribed. To get back on the list, just text in with your password.")
        admin_prefix = "#{user.name} [#{user.phone}] left the list with this message: "
        sms.send_to_admins(admin_prefix + body)
      else
      reply_prefix = user.name.blank? ? "" : "Welcome back!"
      sms.reply(reply_prefix + "Our mojito bots are reviewing your message, and will reply within 2 business days.")
      admin_prefix = "Mojito message from #{user.name} [#{user.phone}]: "
      sms.send_to_admins(admin_prefix + body)
      end
    else
      if body.downcase.include?('mojito')
        user.update!(subscribed: true)
        sms.reply( 'Congrats! You are now subscribed to the Mojito Messenger mailing list! Please reply with your name to finish sign up. And if you ever wanna leave the list, just text STOP.')
        sms.send_to_admins("New sign up from phone number #{sender}!")
      else
       sms.reply( 'A mysterious door opens before you. What is the password?')
       admin_prefix = "Mojito message from unsubscribed user at [#{user.phone}]: "
       sms.send_to_admins(admin_prefix + body)
      end
    end
  else
  case
  when session['pending_dm_message'] && session['pending_dm_phone']
    if body.downcase.start_with?('ok')
      reply = 'Rad, sending it out!'
      sms.send(sender, reply)
      sms.send(session['pending_dm_phone'], session['pending_dm_message'], session['pending_dm_image'])
    else
      reply = 'Your DM was cancelled, nothing got sent'
      sms.send(sender, reply)
    end
    session['pending_dm_message'] = false
    session['pending_dm_image'] = false
    session['pending_dm_phone'] = false
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
  when body.downcase.start_with?('add')
    number = body.split(' ')[1]
    name = body.split(' ')[2..-1].join(' ')
    if !name || !number
      sms.reply("I think you're trying to add somebody?  Your message should look like

add <number> <name>")
    else
      existing_user = User.find_by_phone(number)
      if existing_user
        sms.reply("User exists! #{existing_user.name}'s name to #{name} at #{number}")
        user.update!(name:name)
    else
      User.create!(name:name,phone:number,subscribed:true,admin:false)
      sms.reply("Created user #{name} at #{E164.normalize(number)}")
      sms.send(user.phone, 'Congrats! You are now subscribed to the Mojito Coast text list!  Reply here if you got questions, and if you ever wanna leave the list, just text STOP.')
      end
    end
  when body.downcase.start_with?('send')
    query = body.split(' ')[1]
    search_results = User.find_by_name_or_phone(query)
    puts search_results

    if search_results.empty?
      message = "User #{query} not found, try a different name or a few digits from the phone number you seek."
      return sms.reply(message)
    elsif search_results.length > 1
      message = "Found the below potential recipients. Try a more specific search term, like their last name or a chunk of their phone number"
      search_results.each_with_index do |res,idx|
        message += "
        #{idx + 0} #{res.name} at #{res.phone}"
      end
      session['possible_dm_recipients']=search_results
      return sms.reply(message)
    elsif search_results.length == 1

    outgoing_message = body.split(' ')[2..-1].join(' ')
    session['pending_dm_phone'] = user.phone
    session['pending_dm_message'] = outgoing_message
    session['pending_dm_image'] = image
    confirmation_prefix = "Are you sure you want to send the below? Reply 'OK' if so.
Recipient: #{user.display_name} @ #{user.phone}]

"
    sms.send(sender, confirmation_prefix + outgoing_message, image)
  else
    message = "something went wrong."
    sms.reply(message)
    end
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
end