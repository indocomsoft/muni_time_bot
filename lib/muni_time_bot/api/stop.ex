defmodule MuniTimeBot.API.Stop do
  @moduledoc """
  Provides an abstraction over a stop in the NextBus API.
  """

  @enforce_keys ~w(stop_id coordinate tag route title)a
  defstruct @enforce_keys

  alias MuniTimeBot.API
  alias MuniTimeBot.API.Route
  alias MuniTimeBot.API.Prediction
  alias MuniTimeBot.Coordinate

  @type t :: %__MODULE__{
          stop_id: String.t(),
          coordinate: Coordinate.t(),
          tag: String.t(),
          route: String.t(),
          title: String.t()
        }

  @spec all_stops :: {:ok, [t()]} | {:error, any()}
  def all_stops do
    case Route.all_routes() do
      {:ok, routes} when is_list(routes) -> handle_routes(routes)
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_routes(routes) when is_list(routes) do
    routes
    |> Enum.reduce_while([], fn route, acc ->
      case Route.load(route) do
        {:ok, %Route{stops: stops}} -> {:cont, acc ++ stops}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      routes when is_list(routes) -> {:ok, Enum.uniq_by(routes, & &1.stop_id)}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec new(String.t(), any()) :: {:ok, t()} | :error

  def new(route, api_result = %{"lat" => latitude, "lon" => longitude})
      when is_binary(latitude) and is_binary(longitude) do
    with {float_latitude, _} <- Float.parse(latitude),
         {float_longitude, _} <- Float.parse(longitude),
         {:ok, coordinate} <- Coordinate.new(float_latitude, float_longitude) do
      new(route, api_result, coordinate)
    else
      :error -> :error
    end
  end

  def new(_, _) do
    :error
  end

  @spec new(String.t(), %{required(String.t()) => String.t()}, Coordinate.t()) ::
          {:ok, t()} | :error
  defp new(
         route,
         %{"stopId" => stop_id, "tag" => tag, "title" => title},
         coordinate = %Coordinate{}
       )
       when is_binary(route) and is_binary(stop_id) and is_binary(tag) and is_binary(title) do
    {:ok,
     %__MODULE__{
       stop_id: stop_id,
       coordinate: coordinate,
       tag: tag,
       route: route,
       title: title
     }}
  end

  defp new(_route, _api_result, _coordinate) do
    :error
  end

  @spec predictions(t()) :: {:ok, [Prediction.t()]} | {:error, any()}
  def predictions(%__MODULE__{stop_id: stop_id}) when is_binary(stop_id) do
    case API.request_muni(%{command: "predictions", stopId: stop_id}) do
      {:ok, %{"predictions" => predictions}} when is_list(predictions) ->
        handle_prediction(predictions)

      {:ok, %{"predictions" => prediction}} when is_map(prediction) ->
        handle_prediction([prediction])

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_prediction(predictions) when is_list(predictions) do
    predictions
    |> Enum.reduce_while([], fn raw_prediction, acc ->
      case Prediction.new(raw_prediction) do
        {:ok, prediction = %Prediction{}} -> {:cont, [prediction | acc]}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      predictions when is_list(predictions) -> {:ok, predictions}
      {:error, reason} -> {:error, reason}
    end
  end
end
