defmodule MuniTimeBot do
  @moduledoc """
  Documentation for MuniTimeBot.
  """

  alias MuniTimeBot.API.Stop
  alias MuniTimeBot.Coordinate

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

  def handle(command = {:location, %{latitude: latitude, longitude: longitude}}, cnt) do
    with {:ok, stops} <- Stop.all_stops(),
         {:ok, my_coord} <- Coordinate.new(latitude, longitude) do
      nearest_stops =
        stops
        |> Enum.map(fn stop = %Stop{coordinate: coordinate} ->
          {Coordinate.distance(my_coord, coordinate), stop}
        end)
        |> Enum.sort_by(fn {distance, _stop} -> distance end)
        |> Enum.take(5)
        |> Enum.map(fn {distance, %Stop{title: title}} ->
          "- #{title}: #{Float.round(distance, 2)} m"
        end)
        |> Enum.join("\n")

      answer(
        cnt,
        "Your location is #{latitude}, #{longitude}! The 5 nearest stops are: \n#{nearest_stops}"
      )
    else
      _ -> handle(command, cnt)
    end
  end
end
