#! /usr/bin/ruby

# Download all life expectancy data and put them into JSON files

require 'httparty'

['M', 'F'].each do |gender|
  (0..100).step(5) do |age|
    puts "#{gender} #{age}"
    response = HTTParty.get "http://www.worldlifeexpectancy.com/json-world-life-expectancy-by-age.php?sex=#{gender}&ages=#{age}&order=hight"
    if response.code == 200
      File.open("data/#{gender}_#{age}.json", 'w') {|f| f.write(response.body) }
    else
      puts "Failed"
    end
  end
end
