require 'regexdiv/ast'
require 'regexdiv/simplification'


module Regexdiv
  class Graph
    def initialize(node_count)
      @arcs = (0...node_count).map { [nil] * node_count }
    end

    def node_count
      @arcs.size
    end

    def add_arc(from, to, label)
      if @arcs[from][to]
        @arcs[from][to].operands << label
      else
        @arcs[from][to] = Alternatives.new([label])
      end
    end

    def arc(from, to)
      @arcs[from][to].dup
    end

    def reachable_from(from)
      @arcs[from].map.with_index do |arc, to|
        [to, arc] if arc
      end.compact
    end

    def arrivals_at(to)
      (0...node_count).select do |from|
        @arcs[from][to]
      end.map do |from|
        [from, arc(from, to)]
      end
    end

    def to_s
      (0...node_count).flat_map do |from|
        (0...node_count).map do |to|
          arc = self.arc from, to

          if arc
            "#{from} -#{arc.to_s}-> #{to}"
          else
            nil
          end
        end
      end.compact.join("\n")
    end
  end


  def self.build_graph(base:, modulo:)
    graph = Graph.new(modulo)

    (0...modulo).each do |m|
      (0...base).each do |digit|
        from = m
        to = (m * base + digit) % modulo

        graph.add_arc(from, to, Literal.new(digit.to_s(base)))
      end
    end

    graph
  end


  def self.remove_node(graph, node)
    result = Graph.new(graph.node_count - 1)

    (0...graph.node_count).each do |from|
      from2 = from < node ? from : from - 1

      graph.reachable_from(from).each do |to, label|
        to2 = to < node ? to : to - 1

        result.add_arc(from2, to2, label) if from != node && to != node
      end
    end

    reflexive = graph.arc(node, node)
    reflexive &&= Repetition.new reflexive

    graph.arrivals_at(node).each do |from, label_from|
      graph.reachable_from(node).each do |to, label_to|

        if from != node and to != node
          from2 = from > node ? from-1 : from
          to2 = to > node ? to-1 : to

          extra_arc = Sequence.new([ label_from, reflexive, label_to ].compact)
          result.add_arc(from2, to2, extra_arc)
        end
      end
    end

    result
  end

  def self.derive_regex_ast(base:, modulo:)
    g = build_graph(base: base, modulo: modulo)

    (g.node_count - 1).times do
      g = remove_node(g, g.node_count - 1)
    end

    simplify(Repetition.new(g.arc(0,0)))
  end

  def self.derive_regex_string(**kwargs)
    regex = derive_regex_ast(**kwargs)

    "^#{regex}$"
  end


  def self.derive_regex(**kwargs)
    /^#{derive_regex_string(**kwargs)}$/
  end
end
