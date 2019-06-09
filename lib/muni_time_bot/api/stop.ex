defmodule MuniTimeBot.API.Stop do
  @enforce_keys ~w(stop_id latitude longitude tag route title)a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          stop_id: String.t(),
          latitude: float(),
          longitude: float(),
          tag: String.t(),
          route: String.t(),
          title: String.t()
        }

  alias MuniTimeBot.API.Route

  @spec all_stops :: {:ok, [t()]} | {:error, any()}
  def all_stops do
    case Route.all_routes() do
      {:ok, routes} when is_list(routes) ->
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
  end

  @spec new(String.t(), any()) :: {:ok, __MODULE__.t()} | :error

  def new(route, api_result = %{"lat" => latitude, "lon" => longitude})
      when is_binary(latitude) and is_binary(longitude) do
    with {float_latitude, _} <- Float.parse(latitude),
         {float_longitude, _} <- Float.parse(longitude) do
      new(route, %{api_result | "lat" => float_latitude, "lon" => float_longitude})
    else
      :error -> :error
    end
  end

  def new(route, %{
        "stopId" => stop_id,
        "lat" => latitude,
        "lon" => longitude,
        "tag" => tag,
        "title" => title
      })
      when is_binary(route) and is_binary(stop_id) and is_float(latitude) and is_float(longitude) and
             is_binary(tag) and is_binary(title) do
    {:ok,
     %__MODULE__{
       stop_id: stop_id,
       latitude: latitude,
       longitude: longitude,
       tag: tag,
       route: route,
       title: title
     }}
  end

  def new(_, _) do
    :error
  end
end
