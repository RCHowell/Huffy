defmodule HuffyTest do
  use ExUnit.Case
  doctest Huffy

  test "greets the world" do
    assert Huffy.hello() == :world
  end
end
