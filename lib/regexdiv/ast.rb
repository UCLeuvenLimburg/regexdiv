module Regexdiv
  class Epsilon
    def to_s
      Regexdiv.show self
    end

    def inspect
      to_s
    end

    def ==(x)
      Epsilon === x
    end

    def literals
      []
    end
  end

  Literal = Struct.new :value do
    def to_s
      Regexdiv.show self
    end

    def inspect
      value
    end

    def literals
      [ value ]
    end
  end

  Sequence = Struct.new :operands do
    def to_s
      Regexdiv.show self
    end

    def inspect
      "S(#{operands.map(&:inspect).join(',')})"
    end

    def literals
      operands.flat_map(&:literals)
    end
  end

  Alternatives = Struct.new :operands do
    def to_s
      Regexdiv.show self
    end

    def inspect
      "A(#{operands.map(&:inspect).join('|')})"
    end

    def literals
      operands.flat_map(&:literals)
    end
  end

  Repetition = Struct.new :operand do
    def to_s
      Regexdiv.show self
    end

    def inspect
      "#{operand.inspect}*"
    end

    def literals
      operand.literals
    end
  end

  def self.show(regex, prec=0)
    case regex
    when Epsilon
      '()'

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
