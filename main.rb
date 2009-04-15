#Version 1.0, thanks for reading!
#!/usr/bin/ruby
require 'rubygems'
require 'net/toc'
require 'support.rb'

Net::TOC.new("RPIEvents", "tennis") do |msg, buddy|
  #Input Parsing:
  #If input contains numbers, search and output corresponding databsase row
  #Else, search database and return results with priority
  msg.gsub!(/<\/?[^>]*>/,"")#REMOVES HTML Formatting from text
  result = ""
  Process.abort if msg == 'exit'
  if msg.match(/\d\d+/)
    result = place_num(msg)
  else
    element_array = []
    element_array = msg_parse(msg)
    res1 = place_search(element_array)
    res2 = ""
    result = res1 + res2
    result = "Hello and welcome to RPI People!" if result == ""
    puts result
  end
  buddy.send_im("\n#{result}")
end