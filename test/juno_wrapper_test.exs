defmodule JunoWrapperTest do
  use ExUnit.Case
  doctest JunoWrapper

  test "greets the world" do
    assert JunoWrapper.hello() == :world
  end
end
