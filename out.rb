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

def main
Main = Fiber.new do
@@control["one"] = 0
@@control["two"] = 0
@@control["three"] = 0
skywalker_update
Fiber.yield wait 2
a = 42
b = 37
c = 59
skywalker_update
Fiber.yield wait 2
if (a>41)
@@control["one"] = 53

else
@@control["one"] = 34

end
a = 10
b = 15
c = 20
skywalker_update
Fiber.yield wait 2
a = 30
b = 40
c = 50
skywalker_update
Fiber.yield wait 3
a = 0
b = 0
c = 0
Fiber.yield :end
end
skywalker_update
skywalker_end
end
main