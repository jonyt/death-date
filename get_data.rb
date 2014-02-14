#! /usr/bin/ruby

# Parses the JSON files with life expectancy data and puts the data into a SQLite database

require 'json'
require 'sqlite3'

File.delete('test.db') if File.exists?('test.db')

begin    
  db = SQLite3::Database.open "test.db"
  #db = SQLite3::Database.open ":memory:"
  db.execute "CREATE TABLE IF NOT EXISTS countries(id INTEGER PRIMARY KEY, code TEXT, name TEXT, abbr TEXT)"
  db.execute "CREATE TABLE IF NOT EXISTS life_expectancies(id INTEGER PRIMARY KEY, gender TEXT, age INT, country_id INT, life_expectancy REAL)"
  
  select_country_statement = db.prepare "SELECT id FROM countries WHERE name = ?"   
  insert_country_statement = db.prepare "INSERT INTO countries VALUES (NULL, ?, ?, ?)"
  insert_life_expectancy_statement = db.prepare "INSERT INTO life_expectancies VALUES (NULL, ?, ?, ?, ?)"
  
  files = Dir.glob('data/*')
  
  puts "Processing #{files.size} files"
  
  files.each do |file|
    match = file.scan(/([MF])_(\d+)\.json/)
    gender = match[0][0]
    age = match[0][1]
    
    puts "Inserting for #{gender}, #{age}"
    
    content = IO.read(file).gsub(/,color\:/, ',"color":') # Otherwise JSON parsing fails
    json = JSON.parse content 
    data = json['chart']['countries']['countryitem']
    num_countries = data.size
    num_inserted = 0
    data.each do |country|
      country_id = 0
      country_count = db.get_first_value("SELECT COUNT(*) FROM countries WHERE name = ?", country['name'])
      if country_count == 0
        insert_country_statement.execute(country['id'], country['name'], country['abbr'])
        country_id = db.last_insert_row_id        
      else
        country_id = db.get_first_value("SELECT id FROM countries WHERE name = ?", country['name'])
      end
      
      if country_id > 0
        insert_life_expectancy_statement.execute(gender, age, country_id, country['value'])
        num_inserted += 1
      else 
        puts "Failed to find country_id"  
      end      
    end  
    puts "Inserted #{num_inserted} out of #{num_countries}"
  end
rescue SQLite3::Exception => e    
  puts "Exception occured"
  puts e    
ensure
  select_country_statement.close if select_country_statement
  insert_country_statement.close if insert_country_statement
  insert_life_expectancy_statement.close if insert_life_expectancy_statement
  db.close if db
end
