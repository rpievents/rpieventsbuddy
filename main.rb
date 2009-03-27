#Version 1.0, thanks for reading!
#!/usr/bin/ruby
require 'rubygems'
require 'net/toc'
require 'postgres'

conn = PGconn.connect("localhost", 5432, '', '', "postgres", "postgres", "tennis")
#res  = conn.exec('create people')
#res  = conn.exec("insert into places (id, placename, keywords) values(0,'onion', 'SUP')")
#res  = conn.exec('select p_id, placename, keywords from places2')

#array = conn.query("select * from places2 where p_id='6'")
#puts("ARRAY:")
#array1=array.split
#puts(array1[0][0])
#puts("END ARRAY")

Net::TOC.new("IEDLocalList", "tennis") do |msg, buddy|
  sol = []
  id_Hash = {}
  msg.gsub!(/<\/?[^>]*>/,"")#REMOVES HTML Formatting from text
  result = ""
  if msg.match(/\d\d/) then
    query = "SELECT name, building FROM rpiplaces WHERE p_id = #{msg[/\d\d/]};"
    sol = conn.exec(query)
    sol1 = sol[0][0].gsub(/\s\s+/, "") #removes extra spacing
    sol2 = sol[0][1].gsub(/\s\s+/, "") #removes extra spacing
    result = "#{sol1}, #{sol2}\n"
  else
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
    while(msg.match(/\S+\s/))
      element_Array[x] = msg[/\S+\s/]
      msg[/\S+\s/] = ''
      element_Array[x].gsub!(/\s/,'')
      element_Array[x].gsub!(/_/,' ')
      x=x+1
    end

    weightNames = 20
    weightBuilding = 10
    element_Array.each{|x|
      queryName = "SELECT p_id FROM rpiplaces WHERE name ILIKE \'%#{x}%\';"
      queryBuilding = "SELECT p_id FROM rpiplaces WHERE building ILIKE \'%#{x}%\';"
      arrayNames = conn.exec(queryName)
      arrayBuilding = conn.exec(queryBuilding)
      arrayNames.each{|y|
        id_Hash[y]+=weightNames
      }
      arrayBuilding.each{|y|
        id_Hash[y]+=weightBuilding
      }
    }
    #puts("Final Hashmap")
    t = 0
    answer = []
    id_Hash.sort{|a,b| b[1] <=> a[1]}.each {|elem|
      #  puts "#{elem[1]}, #{elem[0]}"
      if (t < 3 and elem[1] != 0) then
        answer [t] = elem[0]
      end
      t += 1
    }

    result = ""
 
    answer.each{|elem|
      queryName = "SELECT p_id, name, building FROM rpiplaces WHERE p_id = #{elem};"
      sol = conn.exec(queryName)
      sol1 = sol[0][0].gsub(/\s\s+/, "")
      sol2 = sol[0][1].gsub(/\s\s+/, "")
      sol3 = sol[0][2].gsub(/\s\s+/, "")
      result += "#{sol1} - #{sol2}, #{sol3}\n"
    }

    puts result
  end
  buddy.send_im("\n#{result}")
end