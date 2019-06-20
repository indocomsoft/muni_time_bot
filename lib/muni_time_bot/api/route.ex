defmodule MuniTimeBot.API.Route do
  @moduledoc """
  Provides an abstraction over a route in the NextBus API.
  """

  @enforce_keys ~w(tag title)a
  defstruct @enforce_keys ++ ~w(stops inbound_route outbound_route)a

  alias MuniTimeBot.API
  alias MuniTimeBot.API.Stop

  @type stop_tag :: String.t()
  @type t :: %__MODULE__{
          tag: String.t(),
          title: String.t(),
          stops: [Stop.t()] | nil,
          inbound_route: [stop_tag()] | nil,
          outbound_route: [stop_tag()] | nil
        }

  @spec all_routes(keyword()) :: {:ok, [t()]} | {:error, any()}
  def all_routes(opts \\ []) when is_list(opts) do
    case API.request_muni(%{command: "routeList"}, opts) do
      {:ok, %{"route" => routes}} when is_list(routes) ->
        routes
        |> Enum.reduce_while([], fn api_route, acc ->
          case new(api_route) do
            {:ok, route = %__MODULE__{}} -> {:cont, [route | acc]}
            :error -> {:halt, :error}
          end
        end)
        |> case do
          parsed_routes when is_list(parsed_routes) -> {:ok, parsed_routes}
          :error -> {:error, :invalid_api_response}
        end

      {:ok, _} ->
        {:error, :invalid_api_response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec new(any()) :: {:ok, __MODULE__.t()} | :error
  def new(%{"tag" => tag, "title" => title}) when is_binary(tag) and is_binary(title) do
    {:ok, %__MODULE__{tag: tag, title: title}}
  end

  def new(_) do
    :error
  end

  @doc """
  Load the `stops`, `inbound_route`, and `outbound_route` if they are not already loaded.
  """
  @spec load(__MODULE__.t(), keyword()) :: {:ok, __MODULE__.t()} | {:error, any()}

  def load(route, opts \\ [])

  def load(
        route = %__MODULE__{
          tag: tag,
          title: title,
          stops: nil,
          inbound_route: nil,
          outbound_route: nil
        },
        opts
      )
      when is_binary(tag) and is_binary(title) and is_list(opts) do
    with {:ok, %{"route" => %{"direction" => raw_routes, "stop" => raw_stops}}}
         when (is_list(raw_routes) or is_map(raw_routes)) and is_list(raw_stops) <-
           API.request_muni(%{command: "routeConfig", r: tag, terse: true}, opts),
         {:ok, stops} when is_list(stops) <- process_stops(tag, raw_stops),
         %{inbound_route: inbound_route, outbound_route: outbound_route} <-
           process_routes(raw_routes) do
      {:ok, %{route | stops: stops, inbound_route: inbound_route, outbound_route: outbound_route}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def load(route = %__MODULE__{}, _opts) do
    {:ok, route}
  end

  @spec process_stops(String.t(), list()) :: {:ok, [Stop.t()]} | {:error, :invalid_api_response}
  defp process_stops(tag, stops) when is_binary(tag) and is_list(stops) do
    stops
    |> Enum.reduce_while([], fn api_stop, acc ->
      case Stop.new(tag, api_stop) do
        {:ok, stop = %Stop{}} -> {:cont, [stop | acc]}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      parsed_stops when is_list(parsed_stops) -> {:ok, parsed_stops}
      :error -> {:error, :invalid_api_response}
    end
  end

  @spec process_routes(list() | map()) ::
          %{inbound_route: [stop_tag()], outbound_route: [stop_tag()]}

  defp process_routes(route) when is_map(route) do
    process_routes([route])
  end

  defp process_routes(routes) when is_list(routes) do
    processed_routes =
      routes
      |> Enum.map(&process_route/1)
      |> Enum.into(%{})

    inbound_route = processed_routes["Inbound"]
    outbound_route = processed_routes["Outbound"]
    %{inbound_route: inbound_route, outbound_route: outbound_route}
  end

  @spec process_route(%{required(String.t()) => String.t()}) :: {String.t(), [stop_tag()]}
  defp process_route(%{"name" => name, "stop" => stops})
       when is_binary(name) and is_list(stops) do
    {name, Enum.map(stops, fn %{"tag" => stop_id} -> stop_id end)}
  end
end
