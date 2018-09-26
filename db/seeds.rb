# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

require 'populator'

# Create the roles
# Role.where(name: 'SuperUser').first_or_create do |role|
#   role.description = 'Superuser'
# end
#
# Role.where(name: 'Administrator').first_or_create do |role|
#   role.description = 'Administrator'
# end
#
# Role.where(name: 'Operator').first_or_create do |role|
#   role.description = 'Operator'
# end

Administrator.where(email: 'admin@aywalive.com').first_or_create! do |admin|
  admin.first_name = 'John'
  admin.last_name = 'Doe'
  admin.email = 'admin@aywalive.com'
  admin.password = 'aywalive.AdmiN1'
  admin.password_confirmation = 'aywalive.AdmiN1'
end

Country.where(iso_code_alpha_2: 'KE').first_or_create!(name: 'Kenya', iso_code_alpha_2: 'KE', iso_code_num: '404', country_calling_code: '254', currency: 'KES', language: 'en')
Country.where(iso_code_alpha_2: 'UG').first_or_create!(name: 'Uganda', iso_code_alpha_2: 'UG', iso_code_num: '800', country_calling_code: '256', currency: 'UGS', language: 'en')
Country.where(iso_code_alpha_2: 'TZ').first_or_create!(name: 'United Republic Of Tanzania', iso_code_alpha_2: 'TZ', iso_code_num: '834', country_calling_code: '255', currency: 'TZS', language: 'en')
Country.where(iso_code_alpha_2: 'CM').first_or_create!(name: 'Cameroon', iso_code_alpha_2: 'CM', iso_code_num: '120', country_calling_code: '237', currency: 'CAF', language: 'fr')
Country.where(iso_code_alpha_2: 'CM').first_or_create!(name: 'United Kingdom', iso_code_alpha_2: 'GB', iso_code_num: '826', country_calling_code: '44', currency: 'GBP', language: 'en')

