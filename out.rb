#!/bin/env/ruby

require 'curses'

@@vars = {}

Curses.init_screen()

@@win = Curses::Window.new(0, 0, 0, 0)

def skywalker_update
  @@win.setpos(0,0)
  @@win << "Skywalker demo uber alles!! :D \n\n"
  @@vars.each {|a, b| @@win << "Variable #{a}: #{b} \n" }
  @@win.refresh
end

def skywalker_end
  @@win << "\nDone!"
  @@win.refresh
  @@win.getch
  @@win.close
end

def main
controll = 0
@@vars["controll"] = 0
motor = 75
@@vars["motor"] = 75
while(controll<2)
skywalker_update
sleep(5 * 1.75 / 2)
servo = 100
@@vars["servo"] = 100
skywalker_update
sleep(0.5)
servo = 0
@@vars["servo"] = 0
controll = controll + 1
@@vars["controll"] = controll + 1

end
motor = 0
@@vars["motor"] = 0
controll

skywalker_update
skywalker_end
end
main