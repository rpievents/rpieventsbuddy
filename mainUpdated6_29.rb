#!/usr/bin/env ruby
require 'rubygems'
require 'net/toc'
require 'postgres'

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
$column_names = ['title','location','start_time','end_time','date','contact','host','website','description','creator']
#********

#*******************
#* CONNECTS TO AIM *
#*******************
puts "Connecting to AIM server..."
client = Net::TOC.new("RPIEvents","tennis")
client.connect
puts "Connected to AIM server.\n"
#*******************

#************************
#* CONNECTS TO POSTGRES *
#************************
puts "\nConnecting to Postgres..."
#$dbh = DBI.connect('DBI:Pg:database=test;host=localhost', 'postgres', 'tennis')
$conn = PGconn.connect("localhost", 5432, '', '', "postgres", "postgres", "tennis")
puts "Connection successful.\n"
#************************

#*****************
#* PARSE MESSAGE *
#*****************
def msg_parse(msg)
	element_array = []
	msg += ' '
	x=0
	while(msg.match(/\S+\s/))
		element_array[x] = msg[/\S+\s/]
		msg[/\S+\s/] = ''
		element_array[x].gsub!(/\s/,'')
		element_array[x].gsub!(/_/,' ')#Allows for multiword elements using _
		x=x+1
	end
	element_array
end
#*****************

#*******************************
#* PRIORITY SEARCHING FUNCTION *
#*******************************
def event_search(element_array)
	id_hash = {}

	element_array.each do |element|
		$column_names.each do |column|
			query = $conn.exec("SELECT e_id FROM events WHERE #{column} ILIKE \'%#{element}%\';")
			query.each do |y|
        id_hash.merge!({y => 0}) unless id_hash.include?(y)
        id_hash[y] += 1
			end
		end
	end


	#Gets top 3 results
	t = 0
	answer = []
	id_hash.sort{|a,b| b[1] <=> a[1]}.each {|elem|
		#  puts "#{elem[1]}, #{elem[0]}"
		if (t < 3 and elem[1] != 0) then
			answer [t] = elem[0]
		end
		t += 1
	}

	result = ""


    answer.each do |event_num|
      query_name = "SELECT p_id, name, building FROM rpiplaces WHERE p_id = #{event_num};"
      sol = $conn.exec(query_name)
      sol1 = sol[0][0].gsub(/\s\s+/, "")
      sol2 = sol[0][1].gsub(/\s\s+/, "")
      sol3 = sol[0][2].gsub(/\s\s+/, "")
      result += "#{sol1} - #{sol2}, #{sol3}#{ans}\n"
    end


	result
end
#*******************************

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
	# "2a" = events searched
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
		people[buddy] = 1

	#Searching Events

	elsif people[buddy] == 1 and (m =/1/.match(message))
		buddy.send_im "Enter search terms:"
		puts "To #{buddy.screen_name}:Enter search terms:"
		people[buddy] = 2

	elsif people[buddy] == 2
		element_array = []
		element_array = msg_parse(message)
		result = event_search(element_array)

		unless result == ""
			buddy.send_im "#{result}"
			
			buddy.send_im "Say menu to return to the menu, or to view more information about an event reply with the bolded event number."
			people[buddy] = "2a"
		else
			buddy.send_im "No event found. Say menu to return to the menu, or enter a new search."
		end

	elsif people[buddy] == "2a"
		if(m =/^\d+$/.match(message))
			query = $conn.exec("SELECT * FROM events WHERE e_id = #{message}")
			
      buddy.send_im "Title: #{query[0][0]}\nLocation: #{query[0][1]}\nStart time: #{query[0][2]}\nEnd time: #{query[0][3]}\nDate: #{query[0][4]}Contact: #{query[0][5]}\nHost: #{query[0][6]}\nWebsite: #{query[0][7]}\n"
			buddy.send_im "Description: #{query[0][8]}"
			buddy.send_im "Say menu to return to the menu, or enter another event ID to view more details."
		else
			buddy.send_im "Event ID not recognized. Say menu to return to the menu, or try again."
		end

	#elsif people[buddy] == 1 and (m =/1/.match(message))
	#	buddy.send_im "Enter the date you wish to search for: (Month DD, YYYY)"
	#	puts "To #{buddy.screen_name}:Enter the date you wish to search for: (Month DD, YYYY)"
	#	people[buddy] = 2
	#
	#elsif people[buddy] == 2
	#	query = $dbh.prepare("SELECT e_id, title FROM events WHERE date = \'#{message}\'")
	#	query.execute()
	#
	#	eventlist = ""
	#	while row = query.fetch() do
	#		eventlist += "#{row[0]}. #{row[1]}\n"
	#	end
	#	buddy.send_im "#{eventlist}"

	#Adding Event
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
		query = $conn.exec("INSERT INTO events values (\'#{events[buddy].Title}\', \'#{events[buddy].Location}\', \'#{events[buddy].Start}\', \'#{events[buddy].End}\', \'#{events[buddy].Date}\', \'#{events[buddy].Host}\', \'#{events[buddy].Contact}\', \'#{events[buddy].Website}\', \'#{events[buddy].Description}\', \'#{events[buddy].Creator}\');")
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
