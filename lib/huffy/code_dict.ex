defmodule Huffy.CodeDict do
  @me __MODULE__
  @moduledoc """
  CodeDict is used to store codewords while processing a
  Huffman Tree. State is stored within a map in an Agent.

  A key is a source symbol of size r (radix), and a value is a series
  of bits representing the code word

  %{
    << sym :: size(r) >> => << 011 :: size(3) >>,
  }
  """

  def init do
    Agent.start_link(fn -> %{} end, name: @me)
  end

  def add_code(symbol, code) do
    Agent.update(@me, fn(dict) ->
      Map.put(dict, symbol, code)
    end)
  end

  def get_codes() do
    Agent.get(@me, &(&1))
  end

end
