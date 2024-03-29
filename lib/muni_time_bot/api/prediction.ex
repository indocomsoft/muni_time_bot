defmodule MuniTimeBot.API.Prediction do
  @moduledoc """
  Provides an abstraction over a prediction in the NextBus API.
  """

  @enforce_keys ~w(route_title directions)a
  defstruct @enforce_keys

  alias MuniTimeBot.API.Prediction.Direction

  @type t :: %__MODULE__{
          route_title: String.t(),
          directions: [Direction.t()]
        }

  @spec new(any()) :: {:ok, t()} | {:error, any()}

  def new(%{"routeTitle" => route_title, "dirTitleBecauseNoPredictions" => direction_title})
      when is_binary(route_title) and is_binary(direction_title) do
    {:ok,
     %__MODULE__{
       route_title: route_title,
       directions: [%Direction{title: direction_title, details: []}]
     }}
  end

  def new(api_raw = %{"direction" => direction}) when is_map(direction) do
    new(%{api_raw | "direction" => [direction]})
  end

  def new(%{"routeTitle" => route_title, "direction" => directions})
      when is_list(directions) and is_binary(route_title) do
    directions
    |> Enum.reduce_while([], fn raw_direction, acc ->
      case Direction.new(raw_direction) do
        {:ok, direction = %Direction{}} -> {:cont, [direction | acc]}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      directions when is_list(directions) ->
        {:ok, %__MODULE__{route_title: route_title, directions: directions}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def new(_) do
    {:error, __MODULE__}
  end
end
