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

  def self.simplify(regex)
    case regex
    when Sequence
      regex = Sequence.new(regex.operands.map { |operand| simplify(operand) })
      regex = Sequence.new(flatten_sequences(regex.operands))
      regex = unpack_singleton(regex)

    when Alternatives
      regex = Alternatives.new(regex.operands.map { |operand| simplify(operand) })
      regex = Alternatives.new(flatten_alternatives(regex.operands))
      regex = unpack_singleton(regex)

    when Repetition
      regex = Repetition.new(simplify(regex.operand))

    else
      regex
    end
  end
end
