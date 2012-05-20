class AdditionNode
  def initialize(op, left, right)
    @op, @left, @right = op, left, right
  end

  def compile
    "#{@left.compile} #{@op} #{@right.compile}"
  end
end

class CallNode
  def initialize(name)
    @name = name
  end

  def compile
    "Fiber.yield \"call #{@name}\""
  end
end

class MultiNode
  def initialize(op, left, right)
    @op, @left, @right = op, left, right
  end

  def compile
    "#{@left.compile} #{@op} #{@right.compile}"
  end
end

class IntegerNode
  def initialize(a)
    @value = a
  end

  def compile
    "#{@value}"
  end
end

class ParenthesesNode
  def initialize(add)
    @add = add
  end

  def compile
    "(#{@add.compile})"
  end
end

class FloatNode
  def initialize(a)
    @value = a
  end

  def compile
    "#{@value}"
  end
end

class AssignNode
  def initialize(var, expr)
    @var = var
    @expr = expr
  end

  def compile
    "#{@var} = #{@expr.compile}"
  end
end

class ControlsAssignNode
  def initialize(ctrl, expr)
    @ctrl = ctrl
    @expr = expr
  end

  def compile
    "@@control[\"#{@ctrl}\"] = #{@expr.compile}"
  end
end

class IncludeNode
  def initialize(ext)
    @@external = ext
  end

  def compile
    ""
  end
end

class InterfaceVarNode
  def initialize(var)
    @var = var
  end

  def compile
    "#{@var}"
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
    "#{@name} = Fiber.new do\nloop do\n#{@stmt.compile}Fiber.yield :end\nend\nend"
  end
end

class RoutineListNode < Array
  def initialize
  end

  def compile
    temp = ""
    self.each {|a| temp += a.compile + "\n" }
    temp
  end
end
    
    

class IfNode
  def initialize(bool, stmt)
    @bool = bool
    @stmt = stmt
  end

  def compile
    "if (#{@bool.compile})\n#{@stmt.compile}"
  end
end

class ElseNode
  def initialize(stmt)
    @stmt = stmt
  end

  def compile
    "else\n#{@stmt.compile}"
  end
end

class IfElseNode
  def initialize(if_,else_)
    @if = if_
    @else = else_
  end

  def compile
    "#{@if.compile}\n#{@else.compile}\nend"
  end
end

class WhileNode
  def initialize(bool, stmt)
    @bool = bool
    @stmt = stmt
  end

  def compile
    "while(#{@bool.compile})\n#{@stmt.compile}\nend"
  end
end

class WaitNode
  def initialize(time)
    @time = time
  end

  def compile
    "Fiber.yield \"wait #{@time.compile}\""
  end
end

class IdentifierNode
  def initialize(id)
    @id = id
  end

  def compile
    "#{@id}"
  end
end

class BooleanNode
  def initialize(left, op, right)
    @left = left
    @op = op
    @right = right
  end

  def compile
    "#{@left.compile}#{@op}#{@right.compile}"
  end
end

class Dummy
  def initialize
    nil
  end

  def compile
    ""
  end
end

class StmtNode
  def initialize(stmt)
    @stmt = stmt
  end
  
  def compile
    "#{@stmt.compile}\n"
  end
end

class StmtListNode < Array
  def initialize
  end

  def compile
    str = ""
    self.each {|a| str += a.compile}
    str
  end
end
