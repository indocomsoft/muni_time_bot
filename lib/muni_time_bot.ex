defmodule MuniTimeBot do
  @moduledoc """
  Documentation for MuniTimeBot.
  """

  alias MuniTimeBot.StopsWorker
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
    case Coordinate.new(latitude, longitude) do
      {:ok, my_coord} ->
        message =
          StopsWorker.all_stops()
          |> Enum.map(fn stop = %Stop{coordinate: coordinate} ->
            {Coordinate.distance(my_coord, coordinate), stop}
          end)
          |> Enum.sort_by(fn {distance, _stop} -> distance end)
          |> Enum.take(5)
          |> Enum.map(fn {distance, stop = %Stop{title: title, stop_id: stop_id}} ->
            "*#{title}* (#{Float.round(distance, 2)} m, stopId #{stop_id})\n" <>
              case Stop.predictions(stop) do
                {:ok, predictions} ->
                  for %{directions: directions, route_title: route_title} <- predictions,
                      %{details: details, title: direction_title} <- directions do
                    "#{route_title} #{direction_title}\n`#{format_details(details)}`"
                  end
                  |> Enum.join("\n")

                {:error, _} ->
                  "Error retrieving data"
              end
          end)
          |> Enum.join("\n\n")

        answer(cnt, message, parse_mode: "markdown")

      _ ->
        handle(command, cnt)
    end
  end

  @spec format_details(list()) :: String.t()
  defp format_details([]) do
    "None"
  end

  defp format_details(details) when is_list(details) do
    details
    |> Enum.map(fn %{minutes: minutes} -> minutes end)
    |> Enum.join(" | ")
  end
end
