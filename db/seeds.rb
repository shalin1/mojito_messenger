# db/seeds.rb
users = [
  {name: 'Shalin', phone: '+16789367721', subscribed: true, admin: true},
  {name: 'Some User', phone: '+15005550006', subscribed: true, admin: false},
]

users.each do |u|
  User.create(u)
end
