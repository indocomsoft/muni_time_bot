defmodule MuniTimeBot.API.Prediction do
  @enforce_keys ~w(route_title directions)a
  defstruct @enforce_keys

  alias MuniTimeBot.API.Prediction.Direction

  @type t :: %__MODULE__{
          route_title: String.t(),
          directions: [Direction.t()]
        }

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

  def new(%{"routeTitle" => route_title, "direction" => direction})
      when is_map(direction) and is_binary(route_title) do
    case Direction.new(direction) do
      {:ok, direction = %Direction{}} ->
        {:ok, %__MODULE__{route_title: route_title, directions: [direction]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def new(_) do
    {:error, __MODULE__}
  end
end
