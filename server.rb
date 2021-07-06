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
  sender = E164.normalize(params['From'])
  user = User.find_or_create_by(phone: sender)
  body = params['Body']
  image = params['MediaUrl0']
  enter_name_name = body.split(' ').first
  confirm_name_message_to_user = "Are you sure you want your name to be #{enter_name_name} in our system?


Reply with a `ok hoss` to confirm"

  new_subscriber_signed_themself_up_message= "We still need your sexy name, sexy. Text your sexy name to this number and You will be subscribed to the Mojito Coast invite list!
If you ever wanna leave the list, just text I AM BORING to this number.
Coconuts!"

  user_got_signed_up_by_admin_message = 'Congratulations! You are now subscribed to the Mojito Coast invite list! you got questions?, we probably have answers. our sexy agents will answer those little fuckers. live the life you deserve.

reply "I AM BORING" to get off this crazy ride!'

  unsubscribe_message = "You've been unsubscribed. If this was a mistake, which it was, just drop us a line, otherwise,  may you find contentment in some dreary temperate zone!"

  admin_bye_bye_message_prefix = "#{user.name} [#{user.phone}] left the list with this message: "

  reply_to_unsubscribed_user_messages_with_no_password = "you're making a great choice mochaca, a mysterious door opens before you. What is the password?"

  outgoing_message_to_subscribed_user_when_they_text = (user.name.blank? ? "" : "Welcome back to the Coast #{user.name}! ") + "One of our sexy mojito agents will Be back with you within the hour, passionflower."

  subscribed_user_with_no_name_but_we_ask_for_it_reply = "Please hold, one of our sexy agents will be with you shortly.  While waiting, could you please exhale slowly and reply with your name?"

  if body.downcase.start_with?('i am boring')||body.downcase.start_with?('unsubscribe')||body.downcase.start_with?('cance')||body.downcase.start_with?('cancel')
    user.update!(subscribed:false)
    sms.reply(unsubscribe_message )
    sms.send_to_admins(admin_bye_bye_message_prefix + body)

    return
  end

  if !user.subscribed && !user.admin?
    if body.downcase.include?('mojito')
      user.update!(subscribed: true)
      sms.reply(new_subscriber_signed_themself_up_message)
      sms.send_to_admins("New sign up from phone number #{sender}!")

      session['enter_name'] = true
    else
      sms.reply(reply_to_unsubscribed_user_messages_with_no_password)
      admin_prefix = "Mojito message from unsubscribed user at [#{user.phone}]: "
      sms.send_to_admins(admin_prefix + body)
    end

    return
  end

  if !user.admin?
    if user.name
      sms.reply(outgoing_message_to_subscribed_user_when_they_text)
      admin_prefix = "Mojito message from #{user.name} [#{user.phone}]: "
      sms.send_to_admins(admin_prefix + body)

      return
    end

    if session['confirm_name']
      if body.downcase.include?('hoss')
        user.update!(name: session['confirm_name'])
        sms.reply("You got it, #{session['confirm_name']} confirmed!")
        sms.send_to_admins("#{session['confirm_name']} just confirmed their name for number #{user.phone}.")
      else
        sms.reply("Name not set. I'll ask again next time you text.")
      end

      session['enter_name'] = false
      session['confirm_name'] = false
      return
    end

    if session['enter_name']
      sms.reply(confirm_name_message_to_user)

      session['enter_name'] = false
      session['confirm_name'] = enter_name_name

      return
    end

    if user.name.blank?
      sms.reply(subscribed_user_with_no_name_but_we_ask_for_it_reply)
      admin_prefix = "Mojito message from an unnamed user at [#{user.phone}]: "
      sms.send_to_admins(admin_prefix + body)

      session['enter_name'] = true

      return
    end
  end

  if user.admin?
    if session['pending_spam_message']
      if body.downcase.start_with?('hell yeah')
        reply = 'Hell yeah, sending it out!'
        sms.send(sender, reply)
        sms.spam(session['pending_spam_message'], session['pending_spam_image'])
      else
        reply = 'Spam cancelled, nothing got sent'
        sms.send(sender, reply)
      end
      session['pending_spam_message'] = false
      session['pending_spam_image'] = false

      return
    end

    if body.downcase.start_with?('dm')
      query = body.split(' ')[1]
      if !query || query.length.zero?
        sms.reply "i didn't quite get that, syntax is DM <name or phone>"
        return
      end
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
        recipient = search_results.first
        outgoing_message = body.split(' ')[2..-1].join(' ')
        reply = "Rad, sending it out! to #{recipient.name} at #{recipient.phone}."
        sms.send(sender, reply)
        sms.send(recipient.phone, outgoing_message, image)
      else
        message = "something went wrong."
        sms.reply(message)
      end

      return
    end

    if body.downcase.start_with?('spam')
      outgoing_message = body.split(' ')[1..-1].join(' ')
      session['pending_spam_message'] = outgoing_message
      session['pending_spam_image'] = image

      puts image
      reply = "Are you sure you wanna spam the below to #{User.subscribed.count} recipients?  It will cost around $#{(User.subscribed.count / 30.0).round(2) }.  Reply 'hell yeah' to confirm!

----

#{outgoing_message}
      "
      sms.send(sender, reply, image)

      return
    end

    if body.downcase.start_with?('invite')
      if body.split(" ").length < 1
        reply("trying to add somebody?  write INVITE <number> <name (optional)>")
        return
      end

      number = body.split(" ")[1]
      name = body.split(' ')[2]

      if !number || E164.normalize(number).length != 12
        sms.reply("the phone number #{number} is invalid, try again!")
        return
      end
      if User.find_by_phone(number)
        sms.reply("the phone number #{number} for #{User.find_by_phone(number).name} already exists")
        return
      end

      u = User.create(phone: E164.normalize(number), name: name, subscribed: true, admin: false)
      # sms.send(u.phone, user_got_signed_up_by_admin_message)
      sms.reply("OK! Inviting #{u.name || "an unnamed user"} at #{u.phone}")

      return
    end

    sms.reply("I didn't get that!  Valid commands are 'SPAM', 'INVITE', or 'DM'")
  end
end

# TODO: refine below subscription case if needed by ori. needs to handle validations gracefully.
#      if body.downcase.start_with?('everybody')
#      reply_prefix = "Here's everybody on your list right now."
#      contacts = User.all.map{|u|"#{u.name} @ #{u.number}
#  "}
#      sms.reply(reply_prefix + contacts)
#    else
#      reply = "I didn't get that, #{user.name}! Try again to prefix your message with a command. Valid commands include 'SPAM', 'SEND', 'ADD'"
#      sms.send(sender, reply)
#    end
#    end
#  end
#   when body.downcase.start_with?('add')
#     return unless body.split(" ").length > 1
#     number = body.split(' ').drop(1).first
#     parsed_number = E164.normalize(number)
#     name = body.split(' ').drop(2).join(' ')
#     if name.to_s.empty? || name[0] == "1" || number.to_s.length < 11 || parsed_number == "+"
#       sms.reply("I think you're trying to add somebody to the list.
# Your message should look like `ADD <number> <name>`")
#     else
#       existing_user = User.find_by_phone(parsed_number) || User.find_by_name(name)
#       if existing_user
#         sms.reply("User already exists! Try to REMOVE #{existing_user.name} at #{existing_user.number} if you need to make edits to that contact.")
#         user.update!(name:name)
#       else
#         User.create(name:name, phone:number, subscribed:true, admin:false)
#         sms.reply("Created user #{name} at #{E164.normalize(number)}")
#         sms.send(parsed_number, 'Congrats!  You have been subscribed to the Mojito Coast text list!  If you ever wanna leave the list, just text STOP.')
#       end
#     end

