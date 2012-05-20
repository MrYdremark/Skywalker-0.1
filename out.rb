#!/bin/env/ruby

require 'curses'

@@control = {}
@@dbglst = []
Curses.init_screen()

@@win = Curses::Window.new(0, 0, 0, 0)
@@debug = Curses::Window.new(0, 0, 0, 0)
def skywalker_update
  @@i = 0
  @@win.setpos(0,0)
  @@win << " .d8888b.  888                                      888 888                       
d88P  Y88b 888                                      888 888                       
Y88b.      888                                      888 888                       
 \"Y888b.   888  888 888  888 888  888  888  8888b.  888 888  888  .d88b.  888d888 
    \"Y88b. 888 .88P 888  888 888  888  888     \"88b 888 888 .88P d8P  Y8b 888P\"   
      \"888 888888K  888  888 888  888  888 .d888888 888 888888K  88888888 888     
Y88b  d88P 888 \"88b Y88b 888 Y88b 888 d88P 888  888 888 888 \"88b Y8b.     888     
 \"Y8888P\"  888  888  \"Y88888  \"Y8888888P\"  \"Y888888 888 888  888  \"Y8888  888     
                         888                                                      
                    Y8b d88P                                                      
                     \"Y88P\"                                                       
-------------------------------------------------------------------------------------"
  @@win.setpos(12, 0)
  @@control.each {|a, b|
    @@win << "Variable #{a}: #{b} \n"}
  @@win.refresh
  @@dbgi = 1
  @@debug.setpos(0, 100)
  @@debug << "   #### Log: ####"
  @@dbglst.each {|a|
    @@debug.setpos(@@dbgi,100)
    @@debug << "#{a}\n"
    @@dbgi += 1 }
  @@debug.refresh
end

def skywalker_end
  @@debug << "Done! Press any key to quit."
  skywalker_update
  @@win.getch
  @@win.close
  @@debug.close
end

def scheduler
  lista = [Main]
  scope = [Main]
  i = 0

  skywalker_update
  
  loop do
    if (scope.empty?)
      break
    end
    
    con = lista[i].resume
    
    if (con =~ /(wait) (.*)/)
      temp = $2
      @@dbglst << " -- Waiting #{temp} sec"
      skywalker_update
      sleep eval(temp)
    elsif (con =~ /(call) (.*)/)
      name = $2
      temp = eval(name)
      lista.insert(temp)
      scope << temp
      @@dbglst << " -- Calling #{name}"
      skywalker_update
    elsif (con == :end)
      scope.pop
      # @@dbglst << " --Deleting #{scope.last} from the scope"
    else
      puts "FEL!"
    end
    lista.insert(i+1, scope.last)
    skywalker_update
    i += 1
  end
  skywalker_end
end


Main = Fiber.new do
loop do
@@control["servo2"] = 0
@@control["motor"] = 100
a = 0
while(a<=10)
@@control["servo"] = a
Fiber.yield "call Rone"
a += 1

end
Fiber.yield "wait 5"
Fiber.yield :end
end
end
Rone = Fiber.new do
loop do
if (@@control["motor"]==100)
@@control["motor"] = 50

else
Fiber.yield "call Rtwo"

end
Fiber.yield "wait 1"
Fiber.yield :end
end
end
Rtwo = Fiber.new do
loop do
@@control["servo2"] += 10
@@control["motor"] = 100
Fiber.yield :end
end
end

scheduler