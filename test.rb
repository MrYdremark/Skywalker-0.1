# -*- coding: utf-8 -*-
require 'fiber'

def wait(sec)
  sleep(sec)
end

main = Fiber.new do
  loop do
    a = 5
    b = 3
    c = 74
    puts "#{a} : #{b} : #{c}"
    Fiber.yield "wait 5"
    
    a = 54
    b = 123
    c = 456
    puts "#{a} : #{b} : #{c}"
    Fiber.yield "call derp"
    
    a = 567
    b = 345
    c = 4789
    puts "#{a} : #{b} : #{c}"
    Fiber.yield :end
  end
end

derp = Fiber.new do
  loop do
    a = 11
    b = 22
    c = 33
    puts "#{a} : #{b} : #{c}"
    Fiber.yield "wait 5"
    
    a = 55
    b = 66
    c = 77
    puts "#{a} : #{b} : #{c}"
    Fiber.yield :end
  end
end

lista = [main]
scope = [main]
i = 0

loop do
  if (scope.empty?)
    break
  end
  
  con = lista[i].resume
  
  if (con =~ /(wait) (.*)/)
   sleep eval($2)
  elsif (con =~ /(call) (.*)/)
    temp = eval($2)
    lista.insert(temp)
    scope << temp
    puts "Adding #{temp} to the scope"
  elsif (con == :end)
    scope.pop
    puts "Deleting #{scope.last} from the scope"
  else
    puts "FEL!"
  end
  lista.insert(i+1, scope.last)
  i += 1
end

puts "#{lista}"
