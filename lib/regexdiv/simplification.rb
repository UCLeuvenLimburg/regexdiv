require 'regexdiv/ast'


module Regexdiv
  def self.flatten_sequences(rs)
    rs.flat_map do |r|
      if Sequence === r
        flatten_sequences(r.operands)
      else
        [r]
      end
    end
  end

  def self.flatten_alternatives(rs)
    rs.flat_map do |r|
      if Alternatives === r
        flatten_alternatives(r.operands)
      else
        [r]
      end
    end
  end

  def self.unpack_singleton(regex)
    if regex.operands.size == 1
      regex.operands.first
    else
      regex
    end
  end

  def self.literals(ast)
    case ast
    when Literal
      [ ast.value ]

    when Sequence
      ast.operands.flat_map do |operand|
        literals operand
      end

    when Alternatives
      ast.operands.flat_map do |operand|
        literals operand
      end

    when Repetition
      literals ast.operand
    end
  end

  def self.sort_operands(ast)
    sorted_operands = ast.operands.sort do |x, y|
      literals(x).min <=> literals(y).min
    end

    ast.class.new(sorted_operands)
  end

  def self.simplify(ast)
    case ast
    when Sequence
      ast = Sequence.new(ast.operands.map { |operand| simplify(operand) })
      ast = Sequence.new(flatten_sequences(ast.operands))
      ast = unpack_singleton(ast)

    when Alternatives
      ast = Alternatives.new(ast.operands.map { |operand| simplify(operand) })
      ast = sort_operands(ast)
      ast = Alternatives.new(flatten_alternatives(ast.operands))
      ast = unpack_singleton(ast)

    when Repetition
      ast = Repetition.new(simplify(ast.operand))

    else
      ast
    end
  end
end
