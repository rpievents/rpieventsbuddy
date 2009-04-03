#!/usr/bin/env ruby
require 'rubygems'
require 'net/toc'
require 'dbi'

#****************
#* EVENTS CLASS *
#****************
class Event
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
	attr_accessor :Title, :Location, :Start, :End, :Date, :Host, :Contact, :Website, :Description, :Creator
end
#****************

#********
#* VARS *
#********
people = Hash.new
events = Hash.new
#********

#*******************
#* CONNECTS TO AIM *
#*******************
puts "Connecting to AIM server..."
client = Net::TOC.new("TobOfWaffles","tennis")
client.connect
puts "Connected to AIM server.\n"
#*******************

#************************
#* CONNECTS TO POSTGRES *
#************************
puts "\nConnecting to Postgres..."
dbh = DBI.connect('DBI:Pg:database=test;host=localhost', 'postgres', 'tennis')
puts "Connection successful.\n"
#************************

#*****************************
#* ACTION ON MESSAGE RECEIVE *
#*****************************
client.on_im do |message,buddy|
	message.gsub!(/<\/?[^>]*>/,"")
	puts "#{buddy.screen_name}: #{message}"
	
	unless people[buddy]
		people[buddy] = 0
		events[buddy] = Event.new
	end
	
	#***************
	# people[buddy]
	#***************
	# 0 = new conversation
	# 1 = menu
	# 2 = searching events
	# 3 = adding event
	# "3a" = adding event title
	# "3b" = adding start time
	# "3c" = adding end time
	# "3d" = adding date
	#***************
	
	if people[buddy] == 0
		buddy.send_im "Hello and welcome to RPIEventsBuddy.\n1.Search Events.\n2.Create New Event.\nType \"menu\" at any time to see this menu again."
		puts "To #{buddy.screen_name}: Hello and welcome to RPIEventsBuddy.\n1.Search Events.\n2.Create New Event."
		people[buddy] = 1
		
	elsif (m =/menu/.match(message))
		buddy.send_im "1.Search Events.\n2.Create New Event.\nType \"menu\" at any time to see this menu again."
		
	elsif people[buddy] == 1 and (m =/1/.match(message))
		buddy.send_im "Searching events."
		puts "To #{buddy.screen_name}:Searching events."
		people[buddy] = 2
		
	elsif people[buddy] == 1 and (m =/2/.match(message))
		buddy.send_im "Add a new event.\nEnter the title: (max 255 characters)"
		puts "Add a new event.\nEnter the title: (max 255 characters)"
		people[buddy] = 3
		
	elsif people[buddy] == 3
		events[buddy].Title = message
		buddy.send_im "Enter event location: (max 255 characters)"
		people[buddy] = "3a"
		
	elsif people[buddy] == "3a"
		events[buddy].Location = message
		buddy.send_im "Enter start time: (max 10 characters)"
		people[buddy] = "3b"
		
	elsif people[buddy] == "3b"
		events[buddy].Start = message
		buddy.send_im "Enter end time: (max 10 characters)"
		people[buddy] = "3c"
	
	elsif people[buddy] == "3c"
		events[buddy].End = message
		buddy.send_im "Enter event date: (max 100 characters)"
		people[buddy] = "3d"
	
	elsif people[buddy] == "3d"
		events[buddy].Date = message
		buddy.send_im "Enter event host: (max 100 characters)"
		people[buddy] = "3e"
	
	elsif people[buddy] == "3e"
		events[buddy].Host = message
		buddy.send_im "Enter contact information: (max 255 characters)"
		people[buddy] = "3f"
		
	elsif people[buddy] == "3f"
		events[buddy].Contact = message
		buddy.send_im "Enter website (if any - max 1000 characters)"
		people[buddy] = "3g"
		
	elsif people[buddy] == "3g"
		events[buddy].Website = message
		buddy.send_im "Enter Description (max 1000 characters)"
		people[buddy] = "3h"
		
	elsif people[buddy] == "3h"
		events[buddy].Description = message
		buddy.send_im "Please scroll up and confirm that everything you have entered is correct.\nIs everything correct? (yes/no)"
		people[buddy] = "3i"
		
	elsif people[buddy] == "3i" and (m =/y/.match(message))
		events[buddy].Creator = buddy.screen_name
		
		#*****************
		#CREATE EVENT HERE
		#*****************
		
		buddy.send_im "Congratulations. Your event has been entered!\n1.Search Events.\n2.Create New Event.\nType \"menu\" at any time to see this menu again."
		people[buddy] = 1
	
	else
		buddy.send_im "Haven't coded this yet."
		puts "To #{buddy.screen_name}:Haven't coded this yet."	
	end
	
	
	sleep 1
end
#*****************************

client.on_error do |error|
	puts "!! #{error}"
end

client.wait
