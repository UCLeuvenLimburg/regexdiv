def lit(x)
  Regexdiv::Literal.new x
end

def seq(*xs)
  Regexdiv::Sequence.new xs
end

def alt(*xs)
  Regexdiv::Alternatives.new xs
end

def rep(x)
  Regexdiv::Repetition.new x
end


RSpec.describe Regexdiv do
  it "has a version number" do
    expect(Regexdiv::VERSION).not_to be nil
  end
end

RSpec.describe 'Formatting' do
  it "a" do
    r = lit 'a'
    expect(r.to_s).to eq 'a'
  end

  it "ab" do
    r = seq(lit('a'), lit('b'))
    expect(r.to_s).to eq 'ab'
  end

  it "a|b" do
    r = alt(lit('a'), lit('b'))
    expect(r.to_s).to eq 'a|b'
  end

  it "a*" do
    r = rep(lit('a'))
    expect(r.to_s).to eq 'a*'
  end

  it "ab|cd" do
    r = alt(seq(lit('a'), lit('b')), seq(lit('c'), lit('d')))
    expect(r.to_s).to eq 'ab|cd'
  end

  it "(a|b)(c|d)" do
    r = seq(alt(lit('a'), lit('b')), alt(lit('c'), lit('d')))
    expect(r.to_s).to eq '(a|b)(c|d)'
  end

  it "(ab)*" do
    r = rep(seq(lit('a'), lit('b')))
    expect(r.to_s).to eq '(ab)*'
  end

  it "(a|b)*" do
    r = rep(alt(lit('a'), lit('b')))
    expect(r.to_s).to eq '(a|b)*'
  end

  it "(ab)(cd) -> abcd" do
    r = seq(seq(lit('a'), lit('b')), seq(lit('c'), lit('d')))
    expect(r.to_s).to eq 'abcd'
  end

  it "(a|b)|(c|d) -> a|b|c|d" do
    r = alt(alt(lit('a'), lit('b')), alt(lit('c'), lit('d')))
    expect(r.to_s).to eq 'a|b|c|d'
  end

  it "ab*" do
    r = seq(lit('a'), rep(lit('b')))
    expect(r.to_s).to eq 'ab*'
  end
end


RSpec.describe 'derive_regex' do
  (2..3).each do |base|
    (2..5).each do |modulo|
      context("base #{base}, modulo #{modulo}") do
        r = Regexdiv::derive_regex(base: base, modulo: modulo)

        (0..100).each do |k|
          it "works on #{k} (#{k.to_s(base)})" do
            if k % modulo == 0
              expect(r =~ k.to_s(base)).to be_truthy
            else
              expect(r =~ k.to_s(base)).to be_falsey
            end
          end
        end
      end
    end
  end
end

RSpec.describe 'simplify' do
  it "(ab)(cd) -> abcd" do
    regex = seq( seq( lit('a'), lit('b') ), seq( lit('c'), lit('d') ) )
    actual = Regexdiv::simplify regex
    expected = seq( lit('a'), lit('b'), lit('c'), lit('d') )

    expect(actual).to eq expected
  end

  it "(a|b)|(c|d) -> a|b|c|d" do
    regex = alt( alt( lit('a'), lit('b') ), alt( lit('c'), lit('d') ) )
    actual = Regexdiv::simplify regex
    expected = alt( lit('a'), lit('b'), lit('c'), lit('d') )

    expect(actual).to eq expected
  end

  it "singleton sequence" do
    regex = seq( lit('a') )
    actual = Regexdiv::simplify regex
    expected = lit('a')

    expect(actual).to eq expected
  end

  it "singleton alternatives" do
    regex = alt( lit('a') )
    actual = Regexdiv::simplify regex
    expected = lit('a')

    expect(actual).to eq expected
  end

  it "singleton alternatives nested in singleton sequence" do
    regex = seq( alt( lit('a') ) )
    actual = Regexdiv::simplify regex
    expected = lit('a')

    expect(actual).to eq expected
  end

  it "b|a -> a|b" do
    regex = alt( lit('b'), lit('a') )
    actual = Regexdiv::simplify regex
    expected = alt( lit('a'), lit('b') )

    expect(actual).to eq expected
  end
end