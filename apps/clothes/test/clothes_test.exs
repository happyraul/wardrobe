defmodule ClothesTest do
  use ExUnit.Case
  doctest Clothes

  test "greets the world" do
    assert Clothes.hello() == :world
  end
end
