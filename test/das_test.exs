defmodule DasTest do
  use ExUnit.Case
  doctest Das

  test "greets the world" do
    assert Das.hello() == :world
  end
end
