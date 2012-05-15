class AdditionNode
  def initialize(op, a, b)
    @op, @a, @b = op, a, b
  end

  def evaluate
    eval("#{@a.evaluate}#{@op}#{@b.evaluate}")
  end

  def debug
    " -> AdditionNode(#{@a.debug} #{@op} #{@b.debug})"
  end

  def compile
    "#{@a.compile} #{@op} #{@b.compile}"
  end
end

class MultiNode
  def initialize(op, a, b)
    @op, @a, @b = op, a, b
  end

  def evaluate
    eval("#{@a.evaluate}#{@op}#{@b.evaluate}")
  end

  def debug
    " -> MultiNode(#{@a.debug} #{@op} #{@b.debug})"
  end

  def compile
    "#{@a.compile} #{@op} #{@b.compile}"
  end
end

class IntegerNode
  def initialize(a)
    @a = a
  end

  def evaluate
    @a
  end

  def debug
    " -> IntegerNode(#{@a})"
  end

  def compile
    "#{@a}"
  end
end

class FloatNode
  def initialize(a)
    @a = a
  end

  def evaluate
    @a
  end

  def debug
    " -> FloatNode(#{@a})"
  end

  def compile
    "#{@a}"
  end
end

class AssignNode
  def initialize(a,b)
    @a = a
    @b = b
  end

  def evaluate
    c = @b.evaluate
    assignVariable(@a,c)
  end

  def debug
    c = @b.evaluate
    " -> AssignNode(#{assignVariable(@a,c)})"
  end

  def assignVariable(a,b)
    @@vars[a] = b
  end

  def compile
    "#{@a} = #{@b.compile}"
  end
end

class ControlsAssignNode
  def initialize(a, b)
    @a = a
    @b = b
  end

  def compile
    "@@control[\"#{@a}\"] = #{@b.compile}"
  end
end

class IncludeNode
  def initialize(a)
    @@external = a
  end

  def compile
    ""
  end
end

class InterfaceVarNode
  def initialize(a)
    @a = a
  end

  def compile
    "#{@a}"
  end
end

class InterfaceVarListNode < Array
  def initialize
  end

  def compile
    self.each {|a| @@control[a] = 0 }
  end
end

class RoutineNode
  def initialize(name, stmt)
    @name = name
    @stmt = stmt
  end

  def compile
    "#{@name} = Fiber.new do\n#{@stmt.compile}Fiber.yield :end\nend"
  end
end
    

class IfNode
  def initialize(a, b)
    @bool = a
    @stmt = b
  end

  def evaluate
    if @bool.evaluate
      @stmt.evaluate
    else
      nil
    end
  end

  def debug
    " -> If -> Bool(#{@bool.debug}) then -> #{@stmt.debug}"
    nil
  end

  def compile
    "if (#{@bool.compile})\n#{@stmt.compile}"
  end
end

class ElseNode
  def initialize(a)
    @stmt = a
  end

  def compile
    "else\n#{@stmt.compile}"
  end
end

class IfElseNode
  def initialize(a,b)
    @if = a
    @else = b
  end

  def compile
    "#{@if.compile}\n#{@else.compile}\nend"
  end
end

class WhileNode
  def initialize(a, b)
    @bool = a
    @stmt = b
  end

  def evaluate
    while(true)
      if @bool.evaluate
        @stmt.evaluate
      else
        break
      end
    end
  end

  def debug
    " -> While -> Bool(#{@bool.debug} do -> #{@stmt.debug})"
  end

  def compile
    "while(#{@bool.compile})\n#{@stmt.compile}\nend"
  end
end

class WaitNode
  def initialize(a)
    @a = a
  end

  def evaluate
    sleep @a.evaluate
  end

  def debug
    " -> wait #{@a.debug} sek"
  end

  def compile
    "Fiber.yield \"wait #{@a.compile}\""
  end
end

class IdentifierNode
  def initialize(a)
    @a = a
  end

  def evaluate
    @@vars[@a]
  end
  
  def debug
    " -> IdentifierNode(#{@a}) = (#{@@vars[@a]})"
  end

  def compile
    "#{@a}"
  end
end

class BooleanNode
  def initialize(a, b, c)
    @a = a
    @b = b
    @c = c
  end

  def evaluate
    eval("#{@a.evaluate}#{@b}#{@c.evaluate}")
  end

  def debug
    " -> Bool(#{@a.evaluate}#{@b}#{@c.evaluate})"
  end

  def compile
    "#{@a.compile}#{@b}#{@c.compile}"
  end
end

class Dummy
  def initialize
    nil
  end
  def evaluate
    ""
  end
  def compile
    ""
  end
end

class StmtNode
  def initialize(a)
    @a = a
  end
  
  def evaluate
    @a.evaluate
  end
  
  def debug
    " -> StmtNode(#{@a.debug})"
  end

  def compile
    "#{@a.compile}\n"
  end
end

class StmtListNode < Array
  def initialize
  end
  def evaluate
    self.each {|a| a.evaluate }
    self[-1].evaluate
  end

  def debug
    self.each {|a| puts "StmtListNode #{a.debug} \n"}
  end

  def compile
    derp = ""
    self.each {|a| derp += a.compile}

    derp
  end
end
