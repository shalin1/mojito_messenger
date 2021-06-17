welcome to mojito messenger

get started:

set up a twilio account (there is a free tier) and buy a phone number (it's like a dollar)

set up your .env with your account info from the project console  
```
ACCOUNT_SID=Axxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx5
AUTH_TOKEN=7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx6
TWILIO_PHONE=+155555555
```

run `bundle install`

run `rake db:migrate`
run `ruby server.rb` from the command line
