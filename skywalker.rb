require './parser.rb'
require './nodes.rb'
require 'fiber'

class Skywalker
  def initialize
    @skywalker = Parser.new("skywalker") do
      token(/\s+/)
      token(/\d+\.\d+/) {|float| float.to_f }
      token(/\d+/) {|int| int.to_i }
      token(/\w+/) {|str| str }
      token(/!=|<=|>=|==|\+=|-=|\*=|\/=/) {|op| op }
      token(/./) {|wldcrd| wldcrd }
      
      start :start do
        match(:interface, :routine_list) {
          |int, rout| @@interface = int, @@code = rout }
      end

      rule :routine_list do
        match(:routine_list, :routine) {
          |lst, rout| lst << rout }
        match(:routine) {
          |rout| RoutineListNode.new << rout }
      end
      
      rule :interface do
        match("interface", :interface_stmt_list, :terminator) {
          |_, stmt_lst, _, _| stmt_lst }
      end
      
      rule :routine do
        match("routine", /^[a-zA-Z]/, :stmt_list, :terminator) {
          |_, name, stmt_list, _| RoutineNode.new(name, stmt_list) }
      end

      rule :stmt_list do
        match(:stmt) {
          |stmt| StmtListNode.new << StmtNode.new(stmt) }
        match(:stmt_list, :stmt) {
          |lst, stmt| lst << StmtNode.new(stmt) }
      end

      rule :interface_stmt_list do
        match(:interface_stmt) {
          |stmt| StmtListNode.new << StmtNode.new(stmt) }
        match(:interface_stmt_list, :interface_stmt) {
          |lst, _, stmt| lst << StmtNode.new(stmt) }
      end

      rule :interface_stmt do
        match(:include_stmt, ";") {|stmt, _| stmt }
        match(:interface_assign_stmt, ";") {|stmt, _| stmt }
      end

      rule :include_stmt do
        match("external", "(", /.+/, ".", /.+/, ")") {
          |_, _, name, dot, ext, _| IncludeNode.new("#{name}#{dot}#{ext}") }
      end

      rule :interface_assign_stmt do
        match("Controls", "=", "{", :interface_var_list, "}") {
          |_, _, _, var_lst, _| ControlsAssignNode.new(var_lst, 0) } 
      end

      rule :interface_var_list do
        match(:interface_var) {
          |var| InterfaceVarListNode.new << InterfaceVarNode.new(var) }
        match(:interface_var_list, ",", :interface_var) {
          |lst, _, var| lst << InterfaceVarNode.new(var) }
      end

      rule :interface_var do
        match(/[a-zA-Z]/) {|var| var }
      end

      rule :control_assign_stmt do
        match("Controls", "[", /[a-zA-Z]/, "]", "=", :addition) {
          |_, _, name, _, _, expr| ControlsAssignNode.new(name, expr) } 
      end
      
      rule :stmt do
        match(:if_else_stmt) {|stmt| stmt }
        match(:while_stmt) {|stmt| stmt }
        match(:control_assign_stmt, ";") {|stmt, _| stmt }
        match(:assign_stmt, ";") {|stmt, _| stmt }
        match(:wait_stmt, ";") {|stmt, _| stmt }
        match(:addition, ";") {|expr, _| expr } 
      end

      rule :addition do
        match(:multi)
        match(:addition, :addition_oper, :multi) {
          |left, op, right| AdditionNode.new(op, left, right) }
      end
      
      rule :multi do
        match(:primary)
        match(:multi, :multi_oper, :multi) {
          |left, op, right| MultiNode.new(op, left, right) }
      end
      
      rule :primary do
        match("(", :addition, ")") {
          |_, expr, _| ParenthesesNode.new(expr) }
        match(:atom)
      end
      
      rule :atom do
        match(Float) {
          |float| FloatNode.new(float) }
        match(Integer) {
          |int| IntegerNode.new(int) }
        match(:identifier)        
      end

      rule :boolean do
        match("true") {
          |bool| bool }
        match("false") {
          |bool| bool }
      end
      
      rule :terminator do
        match("end") {
          |a| a }
      end
      
      rule :addition_oper do
        match(/\+|-|\+=|-=/) {
          |op| op }
      end

      rule :multi_oper do
        match(/\*|\/|\*=|\/=/) {
          |op| op }
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
        match(:boolean) {
          |bool| BooleanNode.new(Dummy.new, bool, Dummy.new) }
        match(:addition, :rel_oper, :multi) {
          |left, op, right| BooleanNode.new(left, op, right) }
      end
      
      
      rule :if_stmt do
        match("if", "(", :bool_expr, ")", :stmt_list) {
          |_, _, bool, _, stmt| IfNode.new(bool, stmt) }
      end

      rule :else_stmt do
        match("else", :stmt_list) {
          |_, stmt| ElseNode.new(stmt) }
      end

      rule :if_else_stmt do
        match(:if_stmt, :terminator) {
          |stmt, _| IfElseNode.new(stmt, "") }
        match(:if_stmt, :else_stmt, :terminator) {
          |if_stmt, else_etmt, _| IfElseNode.new(if_stmt, else_stmt) }
      end

      rule :while_stmt do
        match("while", "(", :bool_expr, ")", :stmt_list, :terminator) {
          |_, _, bool, _, stmt, _| WhileNode.new(bool, stmt) }
      end

      rule :call do
        match("call", "(", /[a-zA-Z]+/, ")") {
          |_, _, routine, _| CallNode.new(routine) }
      end

      rule :wait_stmt do
        match("wait", "(", :addition, ")") {
          |_, _, time, _| WaitNode.new(time)}
      end
      
      rule :identifier do
        match(/^[a-z]+/) {
          |id| IdentifierNode.new(id) }
      end

      rule :assign_stmt do
        match(/^[a-z]+/, "=", :addition) {
          |var, _, expr| AssignNode.new(var, expr) }
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
