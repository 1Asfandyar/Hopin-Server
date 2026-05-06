# Create admin user
AdminUser.find_or_create_by!(email: 'admin@example.com') do |admin|
  admin.password = 'password123'
  admin.password_confirmation = 'password123'
end

puts "Admin user created: admin@example.com / password123"AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?