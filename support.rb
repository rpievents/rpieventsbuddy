require 'rubygems'
require 'postgres'

#This connects to database
$conn = PGconn.connect("localhost", 5432, '', '', "postgres", "postgres", "tennis")

def is_open(elem)
  ans = ", "
  current_time = Time.new
  day_of_week = current_time.strftime("%A")
  day_of_week = day_of_week.downcase

  query_name = "SELECT p_id, name, building, #{day_of_week} FROM rpiplaces WHERE p_id = #{elem};"
  sol = $conn.exec(query_name)
  #Figure out if location is open at current time
  if sol[0][3] != nil #Check if we have data for this place and time
    sol4 = sol[0][3].gsub(/\s+/, "") #Remove all spaces
    sol5 = sol4.split(/&/) #Spcial case - opens and closes multiple times per day
    open_times = []
    sol5.each {|t|
      open_times += t.split(/\-/) #splits into AM/PM times
    }
    open_flag = false
    t = 0
    z = []
    #Iterate through open times and determine if now is between them
    open_times.each do |x|
      #parse the times into a date
      z[t] = Time.parse(x, current_time)
      #if we have enough data to calaulate
      if (t == 1)
        #Change from Hours and Minutes to minutes
        if (current_time.hour * 60 + current_time.min > z[0].hour * 60 + z[0].min and current_time.hour * 60 + current_time.min < z[1].hour * 60 + z[1].min)
          open_flag = true
        end
        t = 0

      else
        t = t + 1
      end
    end
    #if we've determined that the place is open
    if(open_flag == true)
      ans += "Open"
    else
      ans += "Closed"
    end
    #End of open/close determination

  else
    ans = ""
  end

  ans
end

def place_search(element_array)
    id_hash = {}
    result = ''
    weight_names = 20
    weight_building = 10
    element_array.each do |x|
      query_name = "SELECT p_id FROM rpiplaces WHERE name ILIKE \'%#{x}%\';"
      queryBuilding = "SELECT p_id FROM rpiplaces WHERE building ILIKE \'%#{x}%\';"
      arrayNames = $conn.exec(query_name)
      arrayBuilding = $conn.exec(queryBuilding)
      arrayNames.each do |y|
        id_hash.merge!({ y => 0}) unless id_hash.include?(y)
        id_hash[y] += weight_names
      end
      arrayBuilding.each do |y|
        id_hash.merge!({y => 0}) unless id_hash.include?(y)
        id_hash[y] += weight_building
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
    answer.each do |elem|
      ans = is_open(elem) unless elem == nil
      query_name = "SELECT p_id, name, building FROM rpiplaces WHERE p_id = #{elem};"
      sol = $conn.exec(query_name)
      sol1 = sol[0][0].gsub(/\s\s+/, "")
      sol2 = sol[0][1].gsub(/\s\s+/, "")
      sol3 = sol[0][2].gsub(/\s\s+/, "")
      result += "#{sol1} - #{sol2}, #{sol3}#{ans}\n"
    end
    result
end

def place_num(msg)
    query = "SELECT name, building FROM rpiplaces WHERE p_id = #{msg[/\d\d+/]};"
    sol = $conn.exec(query)
    ans = is_open(msg[/\d\d+/])
    sol1 = sol[0][0].gsub(/\s\s+/, "") #removes extra spacing
    sol2 = sol[0][1].gsub(/\s\s+/, "") #removes extra spacing
    result = "#{sol1}, #{sol2}#{ans}\n"
    result
end

def msg_parse(msg)
      #*****************Parse Message into array of elements for searching by spaces
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