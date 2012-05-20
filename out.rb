#!/bin/env/ruby

require 'curses'

@@control = {}

Curses.init_screen()

@@win = Curses::Window.new(0, 0, 0, 0)

def skywalker_update
  @@win.setpos(0,0)
  @@win << "Skywalker demo uber alles!! :D \n\n"
  @@control.each {|a, b| @@win << "Variable #{a}: #{b} \n" }
  @@win.refresh
end

def skywalker_end
  @@win << "\nDone!"
  @@win.refresh
  @@win.getch
  @@win.close
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
      skywalker_update
      sleep eval($2)
    elsif (con =~ /(call) (.*)/)
      temp = eval($2)
      lista.insert(temp)
      scope << temp
      puts " --Adding #{temp} to the scope"
      skywalker_update
    elsif (con == :end)
      scope.pop
      puts " --Deleting #{scope.last} from the scope"
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
a = 6 / 2 * (1 + 2)
@@control["derp"] = a
Fiber.yield "wait 5"
Fiber.yield :end
end
end

scheduler