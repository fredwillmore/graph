require 'byebug'

class Graph

  attr_accessor :nodes, :edges

  def initialize name
    @name = name
    @nodes = []
    @edges = []
  end

  def build_node name
    @nodes << Node.new(name)
  end

  def find_node node
    if node.is_a? Node
      @nodes.find { |n| n==node } || raise("Node: #{node} not found")
    else
      @nodes.find { |n| n.name==node } || raise("Node: #{name} not found")
    end
  end

  def build_edge node_1, node_2
    node_1 = find_node node_1
    node_2 = find_node node_2

    edge = edge_class.new node_1, node_2
    @edges << edge
    node_1.add_edge edge
    node_2.add_edge edge
  end

  def edge_class
    Edge
  end
end

class Node
  attr_accessor :name, :edges

  def initialize(name)
    @name = name
    @edges = []
  end

  def add_edge(edge)
    @edges << edge
  end

  def edge_to(neighbor)
    @edges.detect { |edge| edge.destination(self) == neighbor }
  end

  def incoming_edges
    @edges.select do |edge|
      edge.end == self
    end
  end

  def outgoing_edges
    @edges.select do |edge|
      edge.start == self
    end
  end
end

class Edge
  def initialize(node_1, node_2)
    @nodes = [node_1, node_2]
  end

  def destination(start_node)
    return nil unless @nodes.include?(start_node)
    (@nodes - [start_node]).first
  end
end

class DirectedEdge < Edge
  attr_accessor :start, :end
  def initialize(node_1, node_2)
    super
    @start = node_1
    @end = node_2
  end

end

class DirectedAcyclicGraph < Graph
  def topological_sort
    sorted = []
    to_sort = head_nodes
    processed_edges = []
    until to_sort.empty? do
      n = to_sort.shift
      n.outgoing_edges.each do |edge|
        processed_edges << edge
        m = edge.end
        if (m.incoming_edges - processed_edges).empty?
          to_sort << m
        end
      end
    end
    unless (edges - processed_edges).empty?
      false
    else
      sorted
    end
  end

# while Q is non-empty do
#     remove a node n from Q
#     insert n into L
#     for each node m with an edge e from n to m do
#         remove edge e from the graph
#         if m has no other incoming edges then
#             insert m into Q
# if graph has edges then
#     output error message (graph has a cycle)
# else
#     output message (proposed topologically sorted order: L)

  def head_nodes
    @nodes.select do |node|
      node.edges.find do |edge|
        edge.end == node
      end.nil?
    end
  end

  def valid?
    acyclic?
  end

  def acyclic?
    topological_sort
  end

  def edge_class
    DirectedEdge
  end

end

class Bayesian < DirectedAcyclicGraph

end

NODES = [
  :income, :payment_history, :age, :debt_income, :assets, :reliability, :future_income, :credit_worthy
]

EDGES = [
  [:income, :future_income],
  [:income, :assets],
  [:payment_history, :reliability],
  [:age, :payment_history],
  [:age, :reliability],
  [:debt_income, :payment_history],
  [:debt_income, :credit_worthy],
  [:assets, :future_income],
  [:reliability, :credit_worthy],
  [:future_income, :credit_worthy]
]


require 'test/unit'

class TestGraph < Test::Unit::TestCase

  def setup
    @g = DirectedAcyclicGraph.new(:my_graph).tap do |g|
      NODES.each { |node| g.build_node(node) }
      EDGES.each do |node_1, node_2|
        g.build_edge g.find_node(node_1), g.find_node(node_2)
      end
    end
  end

  def test_dag
    puts @g.to_s
  end

  def test_head_nodes
    assert_equal @g.head_nodes.map(&:name), [:income, :age, :debt_income]
  end

  def test_valid
    assert @g.valid?

    @g.build_edge :reliability, :debt_income
    assert !@g.valid?
  end

end
