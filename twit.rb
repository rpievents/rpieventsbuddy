# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'rubygems'
require "net/http"
require 'uri'
require 'postgres'
require 'time'

class Twitter
  f= File.open('pass', 'r')
  data = []
  i=0
  f.each_line do |x|
    data[i] = x
    i=i+1
  end
  TW_USER = data[0]
  TW_PASS = data[1]
  TW_URL = 'http://twitter.com/statuses/update.xml'
  MAX_LEN = 140
  def initialize

  end
  def update(msg)
    message = msg
    if message.length > MAX_LEN
      puts "Sorry, your message was #{message.length} characters long; the limit is #{MAX_LEN}."
    elsif message.empty?
      puts "No message text selected!"
    end
    begin
      url = URI.parse(TW_URL)
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth TW_USER, TW_PASS
      req.set_form_data({'status' => message})
      begin
        res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          if res.body.empty?
            puts "Twitter is not responding properly"
          else
            puts 'Twitter update succeeded'
          end
        else
          puts 'Twitter update failed for an unknown reason'
          # res.error!
        end
      rescue
        puts $!
        #puts "Twitter update failed - check username/password"
      end
    rescue SocketError
      puts "Twitter is currently unavailable"
    end
  end
end

while(true)
#************************
#* CONNECTS TO POSTGRES *
#************************
puts "\nConnecting to Postgres..."
#$dbh = DBI.connect('DBI:Pg:database=test;host=localhost', 'postgres', 'tennis')
$conn = PGconn.connect("localhost", 5432, '', '', "postgres", "postgres", "tennis")
puts "Connection successful.\n"
#************************
t = Time.now
y = (t.year).to_s
y.gsub!(/20/, '')
date = "#{t.month}/#{t.day}/#{y}"
$conn.exec ("DELETE FROM Appended")
	$conn.exec ("Insert Into Appended (title, location, start_time, end_time, date, contact, host, website, description, creator, been_twit)
Select title, location, start_time, end_time, date, contact, host, website, description, creator, been_twit from UnionCalendar
Union ALL
Select title, location, start_time, end_time, date, contact, host, website, description, creator, been_twit from events")
query = $conn.exec("SELECT * FROM events WHERE date ILIKE '#{date}' AND been_twit IS FALSE")
response = []
if (query != nil)
  query.each do |x|
    time = x[2]
    temp = time[/\d+:/]
    hour = temp.to_s
    hour.gsub!(':','')
    hour = Integer(hour)
    hour = hour + 12 if time[/pm/i]
    if hour = t.hour + 1
      response << "#{x[0]} tonight in #{x[1]}, #{x[2]}-#{x[3]}.  Contact #{x[5]} for more info."
    end
  end
  twit = Twitter.new()
  response.each do |x|
    puts x
    twit.update('test')
  end
end
sleep(3600)
end