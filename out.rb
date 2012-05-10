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
@@control["one"] = 0
@@control["two"] = 0
@@control["three"] = 0
skywalker_update
sleep(2)
a = 42
b = 37
c = 59
skywalker_update
sleep(2)
a = 10
b = 15
c = 20
skywalker_update
sleep(2)
a = 30
b = 40
c = 50
skywalker_update
sleep(3)
a = 0
b = 0
c = 0

skywalker_update
skywalker_end
end
main