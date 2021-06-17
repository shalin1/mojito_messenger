# db/seeds.rb
users = [
  {name: 'Shalin', phone: '+16789367721'},
]

users.each do |u|
  User.create(u)
end
