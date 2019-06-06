defmodule MuniTimeBotTest do
  use ExUnit.Case
  doctest MuniTimeBot

  test "greets the world" do
    assert MuniTimeBot.hello() == :world
  end
end
