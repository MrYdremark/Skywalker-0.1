require './parser.rb'
require './nodes.rb'
require 'fiber'

class Skywalker
  def initialize
    @skywalker = Parser.new("skywalker") do
      token(/\s+/)
      token(/\d+\.\d+/) {|m| m.to_f }
      token(/\d+/) {|m| m.to_i }
      token(/\w+/) {|m| m }
      token(/./) {|m| m }
      
      start :start do
        match(:interface, :routine_list) {|a, b| @@interface = a, @@code = b }
      end

      rule :routine_list do
        match(:routine_list, :routine) {|a, b| a << b }
        match(:routine) {|a| RoutineListNode.new << a }
      end
      
      rule :interface do
        match("interface", :interface_stmt_list, :terminator) {|_, a, _| a}
      end
      
      rule :routine do
        match("routine", /^[a-zA-Z]/, :stmt_list, :terminator){|_, name, stmt_list, _|
          RoutineNode.new(name, stmt_list) }
      end

      rule :stmt_list do
        match(:stmt) {|a| StmtListNode.new << StmtNode.new(a)}
        match(:stmt_list, ";", :stmt) {|a, _, b| a << StmtNode.new(b)}
      end

      rule :interface_stmt_list do
        match(:interface_stmt) {|a| StmtListNode.new << StmtNode.new(a)}
        match(:interface_stmt_list, ";", :interface_stmt) {|a, _, b|
          a << StmtNode.new(b)}
      end

      rule :interface_stmt do
        match(:include_stmt) {|a| a }
        match(:interface_assign_stmt) {|a| a }
      end

      rule :include_stmt do
        match("external", "(", /.+/, ".", /.+/, ")") {|_, _, a, b, c, _|
          IncludeNode.new("#{a}#{b}#{c}") }
      end

      rule :interface_assign_stmt do
        match("Controls", "=", "{", :interface_var_list, "}") {|_, _, _, a, _|
          ControlsAssignNode.new(a, 0) } 
      end

      rule :interface_var_list do
        match(:interface_var) {|a|
          InterfaceVarListNode.new << InterfaceVarNode.new(a) }
        match(:interface_var_list, ",", :interface_var) {|a, _, b|
          a << InterfaceVarNode.new(b) }
      end

      rule :interface_var do
        match(/[a-zA-Z]/) {|a| a }
      end

      rule :control_assign_stmt do
        match("Controls", "[", /[a-zA-Z]/, "]", "=", :addition) {|_, _, a, _, _, b|
          ControlsAssignNode.new(a, b) } 
      end
      
      rule :stmt do
        match(:if_else_stmt) {|a| a}
        match(:while_stmt) {|a| a}
        match(:control_assign_stmt) {|a| a}
        match(:assign_stmt) {|a| a}
        match(:wait_stmt) {|a| a}
        match(:addition) {|a| a}
      end

      rule :addition do
        match(:multi)
        match(:addition, :addition_oper, :multi) {|a, c, b|
          AdditionNode.new(c, a, b) }
      end
      
      rule :multi do
        match(:primary)
        match(:multi, :multi_oper, :multi) {|a, c, b| MultiNode.new(c, a, b) }
      end
      
      rule :primary do
        match("(", :addition, ")") {|_, a, _| a }
        match(:atom)
      end
      
      rule :atom do
        match(Float) {|a| FloatNode.new(a) }
        match(Integer) {|a| IntegerNode.new(a) }
        match(:identifier)        
        match(";")
      end

      rule :boolean do
        match("true") {|a| a}
        match("false") {|a| a}
      end
      
      rule :terminator do
        match("end") {|a| a}
      end
      
      rule :addition_oper do
        match("+") {|a| a}
        match("-") {|a| a}
      end

      rule :multi_oper do
        match("*") {|a| a}
        match("/") {|a| a}
      end

      rule :rel_oper do
        match("==")
        match("!=")
        match("<=")
        match(">=")
        match("<")
        match(">")
      end

      rule :bool_expr do
        match(:boolean) {|a| BooleanNode.new(Dummy.new, a, Dummy.new)}
        match(:addition, :rel_oper, :multi) {|a, b, c| BooleanNode.new(a, b, c) }
      end
      
      
      rule :if_stmt do
        match("if", "(", :bool_expr, ")", :stmt_list) {|_, _, a, _, b|
          IfNode.new(a,b) }
      end

      rule :else_stmt do
        match("else", :stmt_list) {|_, a| ElseNode.new(a) }
      end

      rule :if_else_stmt do
        match(:if_stmt, :terminator) {|a, _| IfElseNode.new(a,"") }
        match(:if_stmt, :else_stmt, :terminator) {|a, b, _|
          IfElseNode.new(a,b) }
      end

      rule :while_stmt do
        match("while", "(", :bool_expr, ")", :stmt_list, :terminator) {
          |_, _, a, _, b, _|
          WhileNode.new(a,b) }
      end

      rule :call do
        match("call", "(", /[a-zA-Z]+/, ")") {|_, _, routine, _| CallNode.new(routine) }
      end

      rule :wait_stmt do
        match("wait", "(", :addition, ")") {|_, _, a, _| WaitNode.new(a)}
      end
      
      rule :identifier do
        match(/^[a-z]+/) {|a| IdentifierNode.new(a) }
      end

      rule :assign_stmt do
        match(/^[a-z]+/, "=", :addition) {|a, _, b| AssignNode.new(a,b) }
      end
      
    end
  end

  def done(str)
    ["quit","exit","bye",""].include?(str.chomp)
  end
  
  def run
    print "[skywalker] "
    str = gets
    if done(str) then
      puts "Bye."
    else
      @@res = (@skywalker.parse str)
      puts "=> #{@@res.evaluate}"
      # @skywalker.parse(str)
      run
    end
  end

  def runfile(filename)
    code = File.read(filename)
    @@res = (@skywalker.parse code)
    puts "=> #{@@res.evaluate}"
  end

  def compile(filename)
    code = File.read(filename)
    @@res = (@skywalker.parse code)
    external = File.read(@@external)
    File.open("out.rb", 'w') {|f| f.write(external +
                                          "\n" +
                                          @@code.compile +
                                          "\nscheduler") }
  end
  
  def log(state = false)
    if state
      @skywalker.logger.level = Logger::DEBUG
    else
      @skywalker.logger.level = Logger::WARN
    end
  end
end
