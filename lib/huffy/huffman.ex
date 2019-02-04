defmodule Huffy.Huffman do
  use Bitwise, only: <<</2
  require Logger

  # ---------------
  # Public API
  # ---------------

  @doc """
  This method takes a distribution map

    %{
      "s_1": freq_1,
      "s_2": freq_2,
      ....
    }

  Which is a map where source symbols are keys and frequencies
  are values. Using a frequency distribution over a probability
  distribution is better because it avoids rounding errors and avoids
  a final pass over the map values to calculate the probability of
  a source symbol appearing in the source.
  """
  def dist_to_tree(dist) do
    Logger.info("Constructing Huffman Tree...")
    dist
    |> make_node_heap
    |> make_tree_rec
  end

  def tree_to_codes(root) do
    Logger.info("Constructing codewords from Huffman Tree")
    Huffy.CodeDict.init()
    # Root should have an empty codeword
    # Note that "" === <<0::size(0)>>
    Map.put(root, :code, "") |> tree_to_codes_rec
    Huffy.CodeDict.get_codes()
  end

  # ---------------
  # Private Methods
  # ---------------

  # This is the base case of recursively building the Huffman tree.
  # If there is only one element in the heap, then it must be the
  # root node of the tree.
  defp make_tree_rec(heap, 1) do
    Heap.root(heap)
  end

  defp make_tree_rec(heap, _) do
    left = Heap.root(heap)
    heap = Heap.pop(heap)
    right = Heap.root(heap)
    heap = Heap.pop(heap)
    node = make_node(nil, left.freq + right.freq)
      |> Map.put(:left, left)
      |> Map.put(:right, right)
    heap = Heap.push(heap, node)
    make_tree_rec(heap, Heap.size(heap))
  end

  defp make_tree_rec(heap) do
    make_tree_rec(heap, Heap.size(heap))
  end

  defp make_node_heap(dist) do
    dist
    |> Enum.to_list
    |> Enum.map(fn({char, freq}) -> make_node(char, freq) end)
    |> Enum.into(Heap.new(fn(node1, node2) ->
      node1.freq < node2.freq
    end))
  end

  defp make_node(char, freq) do
    %{
      char: char,
      freq: freq,
      code: "",
      left: nil,
      right: nil,
    }
  end

  # Base case of the recurrsion is at a leaf node
  # Pattern match the first parameter on a leaf node
  defp tree_to_codes_rec(%{
      :char => char,
      :left => nil,
      :right => nil,
      :code => code
    }) do
    Huffy.CodeDict.add_code(char, code)
  end

  defp tree_to_codes_rec(node) do
    # Calculate the new codes
    n = bit_size(node.code)
    new_size = n + 1
    << prefix :: size(n) >> = node.code
    shifted = prefix <<< 1
    # Apply codes to existing child nodes
    unless node.left == nil do
      # Construct a modified version of the left node with the appropriate coding
      left_code = << shifted + 1 :: size(new_size) >>
      Map.put(node.left, :code, left_code) |> tree_to_codes_rec
    end
    unless node.right == nil do
      # No point in adding 0 to shifted value of node.code
      right_code = << shifted :: size(new_size) >>
      Map.put(node.right, :code, right_code) |> tree_to_codes_rec
    end
  end

end
