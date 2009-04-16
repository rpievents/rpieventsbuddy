#!/usr/bin/env ruby
require 'rubygems'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
#require 'dbi'

#************************
#* CONNECTS TO POSTGRES *
#************************
#puts "\nConnecting to Postgres..."
#dbh = DBI.connect('DBI:Pg:database=test;host=localhost', 'postgres', 'tennis')
#puts "Connection successful.\n"
#************************

class Event
    @Title
    @Location
    @Start
    @End
    @Date
    @Host
    @Contact
    @Website
    @Description
    @Creator
  attr_accessor :Title, :Location, :Start, :End, :Date, :Host, :Contact, :Website, :Description, :Creator
  def initialize(title, location, start, end1, date, host, contact, website, description, creator)
    @Title = ""
    @Location = ""
    @Start = ""
    @End = ""
    @Date = ""
    @Host = ""
    @Contact = ""
    @Website = ""
    @Description = ""
    @Creator = ""
  end
  def set_info(title, location, start, end1, date, host, contact, website, description, creator)
    @Title = title
    @Location = location
    @Start = start
    @End = end1
    @Date = date
    @Host = host
    @Contact = contact
    @Website = website
    @Description = description
    @Creator = creator
  end
end

source = "http://www.rpi.edu/dept/cct/apps/oth/data/rpiUnionEvents.rss" # url or local file
content = "" # raw content of rss feed will be loaded here
open(source) do |s| content = s.read end
rss = RSS::Parser.parse(content, false)


events = content.split(' ')
events_string = ""
events.each do |s|
  events_string = events_string + s + ' '
end

puts events_string

events_array = []
events_string[/<title>(.+?)<item>/] = ""# get rid of preliminary xml
while events_string.match(/<item>(.+?)<\/item>/)
  #parse title and date
  title = events_string[/<title>(.+?)<\/title>/]
  events_string[/<title>(.+?)<\/title>/] = ""
  title[/<title>/] = ''
  title[/<\/title>/] = ''
  new_title = title.split(" - ")
  #date = new_title[1]
  title = new_title[0]
  #parse link
  website = events_string[/<link>(.+?)<\/link>/]
  events_string[/<link>(.+?)<\/link>/] = ""
  website[/<link>/] = ''
  website[/<\/link>/] = ''
  #parse description
  description = events_string[/<description>(.+?)<\/description>/]
  events_string[/<description>(.+?)<\/description>/] = ""
  description[/<description>/] = ''
  description[/<\/description>/] = ''
  #puts description
  #parse date
  date = description[/, (.+?)20\d\d/]
  date[0,2]=''
  #parse time
  stime = description[/20\d\d (.+?) [:A,P:]M/]
  stime.gsub!(/20\d\d /,"")
  etime = description[/- (.+?) [:A,P:]M/]
  etime.gsub!(/- /,"")

  #parse location
  location = description[/\wM (.+?) \wM (.+?)\./]
  location.gsub!(/\wM (.+?) \wM/,"")


  #add to array
 # puts title
  temp = Event.new(title,0,stime, etime,date,0,0,website,description,0)
  temp.set_info(title,0,stime, etime,date,0,0,website,description,0)
  events_array.push(temp)
  events_string[/<item>(.+?)<\/item>/] = ""
end

events_array.each do |s|
  puts "title ", s.Title
  puts "Location ", s.Location
  puts "Start ", s.Start
  puts "End ", s.End
  puts "Date",s.Date
  puts "Host",s.Host
  puts "contact", s.Contact
  puts "website",s.Website
  puts "Description",s.Description
  puts "creator",s.Creator
  puts " "
#	query = dbh.prepare("INSERT INTO events values (\'#{s.Title}\', \'#{s.Location}\', \'#{s.Start}\', \'#{s.End}\', \'#{s.Date}\', \'#{s.Host}\', \'#{s.Contact}\', \'#{s.Website}\', \'#{s.Description}\', \'#{s.Creator}\');")
#	query.execute()
end

