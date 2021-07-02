  users = [
    {name: 'shalin', phone: '+16789367721', subscribed: true, admin: true},
    {name: 'orien', phone: '+16462217782', subscribed: true, admin: false},
  ]

users.each do |u|
  user = User.find_or_create_by!(phone:u[:phone])
  user.update!(name:u[:name], subscribed:true, admin:false)
end
