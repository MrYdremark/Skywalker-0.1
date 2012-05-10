#!/usr/bin/env ruby
# -*- coding: utf-8 -*-


@@vars = {}
@@control = {}
@@res = ""
@@external = ""

@@interface = ""
@@code = ""

# 2010-02-11 New version of this file for the 2010 instance of TDP007
#   which handles false return values during parsing, and has an easy way
#   of turning on and off debug messages.

require 'logger'

class Rule

  # A rule is created through the rule method of the Parser class, like this:
  #   rule :term do
  #     match(:term, '*', :dice) {|a, _, b| a * b }
  #     match(:term, '/', :dice) {|a, _, b| a / b }
  #     match(:dice)
  #   end
  
  Match = Struct.new :pattern, :block
  
  def initialize(name, parser)
    @logger = parser.logger
    # The name of the expressions this rule matches
    @name = name
    # We need the parser to recursively parse sub-expressions occurring 
    # within the pattern of the match objects associated with this rule
    @parser = parser
    @matches = []
    # Left-recursive matches
    @lrmatches = []
  end
  
  # Add a matching expression to this rule, as in this example:
  #   match(:term, '*', :dice) {|a, _, b| a * b }
  # The arguments to 'match' describe the constituents of this expression.
  def match(*pattern, &block)
    match = Match.new(pattern, block)
    # If the pattern is left-recursive, then add it to the left-recursive set
    if pattern[0] == @name
      pattern.shift
      @lrmatches << match
    else
      @matches << match
    end
  end
  
  def parse
    # Try non-left-recursive matches first, to avoid infinite recursion
    match_result = try_matches(@matches)
    return nil if match_result.nil?
    loop do
      result = try_matches(@lrmatches, match_result)
      return match_result if result.nil?
      match_result = result
    end
  end

  private
  
  # Try out all matching patterns of this rule
  def try_matches(matches, pre_result = nil)
    match_result = nil
    # Begin at the current position in the input string of the parser
    start = @parser.pos
    matches.each do |match|
      # pre_result is a previously available result from evaluating expressions
      result = pre_result ? [pre_result] : []

      # We iterate through the parts of the pattern, which may be e.g.
      #   [:expr,'*',:term]
      match.pattern.each_with_index do |token,index|
        
        # If this "token" is a compound term, add the result of
        # parsing it to the "result" array
        if @parser.rules[token]
          result << @parser.rules[token].parse
          if result.last.nil?
            result = nil
            break
          end
          @logger.debug("Matched '#{@name} = #{match.pattern[index..-1].inspect}'")
        else
          # Otherwise, we consume the token as part of applying this rule
          nt = @parser.expect(token)
          if nt
            result << nt
            if @lrmatches.include?(match.pattern) then
              pattern = [@name]+match.pattern
            else
              pattern = match.pattern
            end
            @logger.debug("Matched token '#{nt}' as part of rule '#{@name} <= #{pattern.inspect}'")
          else
            result = nil
            break
          end
        end
      end
      if result
        if match.block
          match_result = match.block.call(*result)
        else
          match_result = result[0]
        end
        @logger.debug("'#{@parser.string[start..@parser.pos-1]}' matched '#{@name}' and generated '#{match_result.inspect}'") unless match_result.nil?
        break
      else
        # If this rule did not match the current token list, move
        # back to the scan position of the last match
        @parser.pos = start
      end
    end
    
    return match_result
  end
end

class Parser

  attr_accessor :pos
  attr_reader :rules, :string, :logger

  class ParseError < RuntimeError
  end

  def initialize(language_name, &block)
    @logger = Logger.new(STDOUT)
    @lex_tokens = []
    @rules = {}
    @start = nil
    @language_name = language_name
    instance_eval(&block)
  end
  
  # Tokenize the string into small pieces
  def tokenize(string)
    @tokens = []
    @string = string.clone
    until string.empty?
      # Unless any of the valid tokens of our language are the prefix of
      # 'string', we fail with an exception
      raise ParseError, "unable to lex '#{string}" unless @lex_tokens.any? do |tok|
        match = tok.pattern.match(string)
        # The regular expression of a token has matched the beginning of 'string'
        if match
          @logger.debug("Token #{match[0]} consumed")
          # Also, evaluate this expression by using the block
          # associated with the token
          @tokens << tok.block.call(match.to_s) if tok.block
          # consume the match and proceed with the rest of the string
          string = match.post_match
          true
        else
          # this token pattern did not match, try the next
          false
        end # if
      end # raise
    end # until
  end
  
  def parse(string)
    # First, split the string according to the "token" instructions given.
    # Afterwards @tokens contains all tokens that are to be parsed. 
    tokenize(string)

    # These variables are used to match if the total number of tokens
    # are consumed by the parser
    @pos = 0
    @max_pos = 0
    @expected = []
    # Parse (and evaluate) the tokens received
    result = @start.parse
    # If there are unparsed extra tokens, signal error
    if @pos != @tokens.size
      raise ParseError, "Parse error. expected: '#{@expected.join(', ')}', found '#{@tokens[@max_pos]}'"
    end
    return result
  end
  
  def next_token
    @pos += 1
    return @tokens[@pos - 1]
  end

  # Return the next token in the queue
  def expect(tok)
    t = next_token
    if @pos - 1 > @max_pos
      @max_pos = @pos - 1
      @expected = []
    end
    return t if tok === t
    @expected << tok if @max_pos == @pos - 1 && !@expected.include?(tok)
    return nil
  end
  
  def to_s
    "Parser for #{@language_name}"
  end

  private
  
  LexToken = Struct.new(:pattern, :block)
  
  def token(pattern, &block)
    @lex_tokens << LexToken.new(Regexp.new('\\A' + pattern.source), block)
  end
  
  def start(name, &block)
    rule(name, &block)
    @start = @rules[name]
  end
  
  def rule(name,&block)
    @current_rule = Rule.new(name, self)
    @rules[name] = @current_rule
    instance_eval &block
    @current_rule = nil
  end
  
  def match(*pattern, &block)
    @current_rule.send(:match, *pattern, &block)
  end

end

##############################################################################
#
# This part defines the dice language
#
##############################################################################

class DiceRoller
        
  def DiceRoller.roll(times, sides)
    (1..times).inject(0) {|sum, _| sum + rand(sides) + 1 }
  end
  
  def initialize
    @diceParser = Parser.new("dice roller") do
      token(/\s+/)
      token(/\d+/) {|m| m.to_i }
      token(/./) {|m| m }
      
      start :expr do 
        match(:expr, '+', :term) {|a, _, b| a + b }
        match(:expr, '-', :term) {|a, _, b| a - b }
        match(:term)
      end
      
      rule :term do 
        match(:term, '*', :dice) {|a, _, b| a * b }
        match(:term, '/', :dice) {|a, _, b| a / b }
        match(:dice)
      end

      rule :dice do
        match(:atom, 'd', :sides) {|a, _, b| DiceRoller.roll(a, b) }
        match('d', :sides) {|_, b| DiceRoller.roll(1, b) }
        match(:atom)
      end
      
      rule :sides do
        match('%') { 100 }
        match(:atom)
      end
      
      rule :atom do
        # Match the result of evaluating an integer expression, which
        # should be an Integer
        match(Integer)
        match('(', :expr, ')') {|_, a, _| a }
      end
    end
  end
  
  def done(str)
    ["quit","exit","bye",""].include?(str.chomp)
  end
  
  def roll
    print "[diceroller] "
    str = gets
    if done(str) then
      puts "Bye."
    else
      puts "=> #{@diceParser.parse str}"
      roll
    end
  end

  def log(state = true)
    if state
      @diceParser.logger.level = Logger::DEBUG
    else
      @diceParser.logger.level = Logger::WARN
    end
  end
end
#-------------------------------------------------------------------

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
              

class IfElseNode
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
    "if (#{@bool})\n#{@stmt}\nend"
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
    "skywalker_update\nsleep(#{@a.compile})"
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

class Skywalker
  def initialize
    @skywalker = Parser.new("skywalker") do
      token(/\s+/)
      token(/\d+\.\d+/) {|m| m.to_f }
      token(/\d+/) {|m| m.to_i }
      token(/\w+/) {|m| m }
      token(/./) {|m| m }
      
      start :start do
        match(:interface, :routine) {|a, b| @@interface = a, @@code = b }
      end
      
      rule :interface do
        match("interface", :interface_stmt_list, :terminator) {|a| a }
      end
      
      rule :routine do
        match("routine", "Main", :stmt_list, :terminator) {|_, _, a, _| a }
      end

      rule :stmt_list do
        match(:stmt) {|a| StmtListNode.new << StmtNode.new(a)}
        match(:stmt_list, ";", :stmt) {|a, _, b| a << StmtNode.new(b)}
      end

      rule :interface_stmt_list do
        match(:interface_stmt) {|a| StmtListNode.new << StmtNode.new(a)}
        match(:interface_stmt_list, ";", :interface_stmt) {|a, _, b| a << StmtNode.new(b)}
      end

      rule :interface_stmt do
        match(:include_stmt) {|a| a }
        match(:interface_assign_stmt) {|a| a }
      end

      rule :include_stmt do
        match("external", "(", /.+/, ".", /.+/, ")") {|_, _, a, b, c, _| IncludeNode.new("#{a}#{b}#{c}") }
      end

      rule :interface_assign_stmt do
        match("Controls", "=", "{", :interface_var_list, "}") {|_, _, _, a, _| ControlsAssignNode.new(a, 0) } 
      end

      rule :interface_var_list do
        match(:interface_var) {|a| InterfaceVarListNode.new << InterfaceVarNode.new(a) }
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
        match(:addition, :addition_oper, :multi) {|a, c, b| AdditionNode.new(c, a, b) }
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
      
      
      rule :if_else_stmt do
        match("if", "(", :bool_expr, ")", :stmt_list, :terminator) {|_, _, a, _, b, _|
          IfElseNode.new(a,b) }
      end

      rule :while_stmt do
        match("while", "(", :bool_expr, ")", :stmt_list, :terminator) {|_, _, a, _, b, _|
          WhileNode.new(a,b) }
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
                                          "def main\n" +
                                          @@code.compile +
                                          "\nskywalker_update" +
                                          "\nskywalker_end" +
                                          "\nend\nmain") }
  end
    
  def log(state = false)
    if state
      @skywalker.logger.level = Logger::DEBUG
    else
      @skywalker.logger.level = Logger::WARN
    end
  end
end

# Examples of use

# irb(main):1696:0> DiceRoller.new.roll
# [diceroller] 1+3
# => 4
# [diceroller] 1+d4
# => 2
# [diceroller] 1+d4
# => 3
# [diceroller] (2+8*d20)*3d6
# => 306
