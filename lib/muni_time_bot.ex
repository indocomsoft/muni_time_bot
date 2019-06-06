defmodule MuniTimeBot do
  @moduledoc """
  Documentation for MuniTimeBot.
  """

  use ExGram.Bot, name: Application.get_env(:muni_time_bot, :name)

  command("start")
  command("help")

  def handle({:command, :start, %{from: %{first_name: first_name}}}, cnt)
      when is_binary(first_name) do
    answer(
      cnt,
      "Welcome to Muni Time Bot, #{first_name}! " <>
        "Please send me your location to find out the time for next muni near you!",
      reply_markup: %{
        keyboard: [[%{request_location: true, text: "Send Location"}]],
        resize_keyboard: true
      }
    )
  end

  def handle({:location, %{latitude: latitude, longitude: longitude}}, cnt) do
    answer(cnt, "Your location is #{latitude}, #{longitude}!")
  end
end
