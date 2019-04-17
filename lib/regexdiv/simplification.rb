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
      [ 'z', *literals(x) ].min <=> [ 'z', *literals(y) ].min
    end

    ast.class.new(sorted_operands)
  end

  def self.factor_alternatives_suffix(ast)
    if Alternatives === ast
      if ast.operands.all? { |operand| Sequence === operand } and ast.operands.map { |seq| seq.operands.last }.uniq.size == 1
        alts = Alternatives.new(ast.operands.map do |seq|
          Sequence.new(seq.operands[0...-1])
        end)

        factored = ast.operands.first.operands.last

        simplify Sequence.new([alts, factored])
      else
        ast
      end
    else
      ast
    end
  end

  def self.factor_alternatives_prefix(ast)
    if Alternatives === ast
      if ast.operands.all? { |operand| Sequence === operand } and ast.operands.map { |seq| seq.operands.first }.uniq.size == 1
        alts = Alternatives.new(ast.operands.map do |seq|
          Sequence.new(seq.operands[1..-1])
        end)

        factored = ast.operands.first.operands.first

        simplify Sequence.new([factored, alts])
      else
        ast
      end
    else
      ast
    end
  end

  def self.factor_alternatives(ast)
    factor_alternatives_prefix(factor_alternatives_suffix(ast))
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
      ast = factor_alternatives_suffix(ast)
      ast = factor_alternatives_prefix(ast)
      ast = unpack_singleton(ast)

    when Repetition
      ast = Repetition.new(simplify(ast.operand))

    else
      ast
    end
  end
end
