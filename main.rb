#Chris Brown
#Rob Margolies
#Pete Lanciani
#Eric Cunningham
#!/usr/bin/ruby
require 'rubygems'
require 'net/toc'
require 'postgres'
#creates the connection to the local PostgreSQL server
conn = PGconn.connect("localhost", 5432, '', '', "postgres", "postgres", "tennis")
#res  = conn.exec('create people')
#res  = conn.exec("insert into places (id, placename, keywords) values(0,'onion', 'SUP')")
#res  = conn.exec('select p_id, placename, keywords from places2')

#array = conn.query("select * from places2 where p_id='6'")
#puts("ARRAY:")
#array1=array.split
#puts(array1[0][0])
#puts("END ARRAY")

#When an IM arrives, do this
Net::TOC.new("IEDLocalList", "tennis") do |msg, buddy|
  sol = []
  id_Hash = {}
  msg.gsub!(/<\/?[^>]*>/,"")#REMOVES HTML Formatting from text
  result = ""
  #If there are two numbers in the msg, we assume that they are searching for
  #a particular place with that number as the ID.  Look for that pattern (numbernumber)
  #and return that particular row.  Else, preform a search
  if msg.match(/\d\d/) then # find two numbers in a row
    query = "SELECT name, building FROM rpiplaces WHERE p_id = #{msg[/\d\d/]};" #create SQL query
    sol = conn.exec(query) #retreve table row
    sol1 = sol[0][0].gsub(/\s\s+/, "") #removes extra spacing
    sol2 = sol[0][1].gsub(/\s\s+/, "") #removes extra spacing
    result = "#{sol1}, #{sol2}\n" #create output string
    if(result == "")
      result = "ID not found"
    end
  else
    #Preform a search
    #***************MAKING THE HASH MAP WITH DEFAULT VALUES FOR P_ID
    query = "SELECT p_id FROM rpiplaces"

    id_Array = conn.exec(query)#Querying database for P_id
    id_Array.each{ |x|#Adding to hasmap
      id_Hash.merge!({x=>0})
    }


    #*****************Parse Message
    element_Array = []
    msg += ' '
    x=0
    while(msg.match(/\S+\s/)) #while there is one or more non-whitespace characters followed by a whitespace character 
      element_Array[x] = msg[/\S+\s/] #add that string to an array
      msg[/\S+\s/] = '' #remove it from the msg
      element_Array[x].gsub!(/\s/,'') #remove any whitespace characters
      element_Array[x].gsub!(/_/,' ') #remove any underscores
      x=x+1 #increment element_array counter
    end

    weightNames = 20 #weight of column names
    weightBuilding = 10 #weight of column building
    element_Array.each{|x| #iterate through the array
      queryName = "SELECT p_id FROM rpiplaces WHERE name ILIKE \'%#{x}%\';" #create query to find matching names
      queryBuilding = "SELECT p_id FROM rpiplaces WHERE building ILIKE \'%#{x}%\';" #create query to find matching buidlings
      arrayNames = conn.exec(queryName) #execute queries
      arrayBuilding = conn.exec(queryBuilding)
      arrayNames.each{|y| #iterate through results, adding the weight for each one
        id_Hash[y]+=weightNames
      }
      arrayBuilding.each{|y| #iterate through results, adding the weight to each one
        id_Hash[y]+=weightBuilding
      }
    }
    #puts("Final Hashmap")
    t = 0
    answer = []
    #sort the hash and pick the top 3 solutions (only pick ones with a value > 0
    id_Hash.sort{|a,b| b[1] <=> a[1]}.each {|elem|
      #  puts "#{elem[1]}, #{elem[0]}"
      if (t < 3 and elem[1] != 0) then
        answer [t] = elem[0]
      end
      t += 1
    }
    #make sure result is clear
    result = ""
 
    answer.each{|elem| #iterate through top three, adding complete information about each
      queryName = "SELECT p_id, name, building FROM rpiplaces WHERE p_id = #{elem};"
      sol = conn.exec(queryName)
      sol1 = sol[0][0].gsub(/\s\s+/, "") #remove all whitespace of form [whitespace][one or more whitespace]
      sol2 = sol[0][1].gsub(/\s\s+/, "") #these don't remove a single space, but two or more spaces or
      sol3 = sol[0][2].gsub(/\s\s+/, "") #new lines (or tabs, etc) are removed
      result += "#{sol1} - #{sol2}, #{sol3}\n" #format results and create response.
    }
    #here for debugging
    puts result
  end
  buddy.send_im("\n#{result}") #respond to the request
end