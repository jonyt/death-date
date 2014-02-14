#! /usr/bin/ruby

# Looks up and says the user's death date

require 'sqlite3'
require 'httparty'
require 'json'
#require 'festivaltts4r'

class Fixnum
  def ordinalize
    if (11..13).include?(self % 100)
      "#{self}th"
    else
      case self % 10
        when 1; "#{self}st"
        when 2; "#{self}nd"
        when 3; "#{self}rd"
        else    "#{self}th"
      end
    end
  end
end

country_code = 'IL'

do_ip_lookup = true
if do_ip_lookup # Lookup user's location
  ip = HTTParty.get 'http://whatismyip.akamai.com'
  location_info = HTTParty.get "http://freegeoip.net/json/#{ip}"
  json = JSON.parse location_info.body
  country_code = json['country_code']
end 

print "Age? "
age = gets.chomp.to_i
rounded_age = 5 * (age / 5.0).round
print "Gender? "
gender = gets.chomp.upcase

begin    
  db = SQLite3::Database.open "life_expectancies.db"  
  life_expectancy = db.get_first_value("SELECT life_expectancy FROM life_expectancies l JOIN countries c ON l.country_id = c.id WHERE gender = ? AND age = ? AND code = ?", gender, rounded_age, country_code)
  life_expectancy_secs = (life_expectancy - age - (age - rounded_age))*86400*365
  death_date = Time.now + life_expectancy_secs
  message = death_date.strftime("You will die on %A %B #{death_date.day.ordinalize} %Y")
  #{}`espeak -ven+f3 -k5 -s150 "#{message}"`
  #message.to_speech
  `./speech.sh "#{message}"`
rescue SQLite3::Exception => e    
  puts "Exception occured"
  puts e    
ensure
  db.close if db
end

# See http://stackoverflow.com/a/2311415/259288 for how to calculate time span to death
