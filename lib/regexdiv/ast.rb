module Regexdiv
  Literal = Struct.new :value do
    def to_s
      Regexdiv.show self
    end

    def inspect
      value
    end
  end

  Sequence = Struct.new :operands do
    def to_s
      Regexdiv.show self
    end

    def inspect
      "S(#{operands.map(&:inspect).join})"
    end
  end

  Alternatives = Struct.new :operands do
    def to_s
      Regexdiv.show self
    end

    def inspect
      "A(#{operands.map(&:inspect).join('|')})"
    end
  end

  Repetition = Struct.new :operand do
    def to_s
      Regexdiv.show self
    end

    def inspect
      "#{operand.inspect}*"
    end
  end

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
        flatten_sequences(r.operands)
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

  def self.show(regex, prec=0)
    case regex
    when Literal
      regex.value

    when Sequence
      str = regex.operands.map { |operand| show(operand, 2) }.join

      if prec > 2
        "(#{str})"
      else
        str
      end

    when Alternatives
      str = regex.operands.map { |operand| show(operand, 1) }.join('|')

      if prec > 1
        "(#{str})"
      else
        str
      end

    when Repetition
      str = show(regex.operand, 3)

      "#{str}*"
    end
  end
end
