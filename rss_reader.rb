#RPI Events Buddy

require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'

class Event
  @Title = ""
  @Date = ""
  @Time = ""
  @Description = ""
  @Link = ""
  attr_accessor :Title, :Date, :Time, :Description, :Link
  def initialize(title,date,time,description,link)
    @Title = title
    @Date = date
    @Time = time
    @Desciption = description
    @Link = link
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

events_array = []
events_string[/<title>(.+?)<item>/] = "" #get rid of preliminary xml
while events_string.match(/<item>(.+?)<\/item>/)
  #parse title and date
  title = events_string[/<title>(.+?)<\/title>/]
  events_string[/<title>(.+?)<\/title>/] = ""
  title[/<title>/] = ''
  title[/<\/title>/] = ''
  new_title = title.split(" - ")
  date = new_title[1]
  title = new_title[0]
  #parse link
  link = events_string[/<link>(.+?)<\/link>/]
  events_string[/<link>(.+?)<\/link>/] = ""
  link[/<link>/] = ''
  link[/<\/link>/] = ''
  #parse description
  description = events_string[/<description>(.+?)<\/description>/]
  events_string[/<description>(.+?)<\/description>/] = ""
  description[/<description>/] = ''
  description[/<\/description>/] = ''
  #add to array
  temp = Event.new(title,date,0,description,link)
  events_array.push(temp)
end

