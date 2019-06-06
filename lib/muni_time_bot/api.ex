defmodule MuniTimeBot.API do
  @moduledoc """
  This module provides an abstraction of the NextBus API.
  """

  @api_base_url "http://webservices.nextbus.com/service/publicJSONFeed"
  @agency "sf-muni"

  @spec all_stops :: [%{required(String.t()) => String.t()}]
  def all_stops do
    route_list!()
    |> Enum.map(&Task.async(fn -> stops_in_route!(&1) end))
    |> Enum.flat_map(&Task.await/1)
    |> Enum.uniq_by(& &1["stopId"])
  rescue
    MatchError -> {:error, :something_failed}
  end

  @spec route_list :: {:ok, [String.t()]} | {:error, any()}
  def route_list do
    case request_muni(%{command: "routeList"}) do
      {:ok, %{"route" => routes}} when is_list(routes) -> {:ok, Enum.map(routes, & &1["tag"])}
      {:ok, _} -> {:error, :unexpected_response}
      {:error, reason} -> {:error, reason}
    end
  end

  def route_list! do
    {:ok, result} = route_list()
    result
  end

  @spec stops_in_route(String.t()) :: {:ok, [String.t()]} | {:error, any()}
  def stops_in_route(tag) when is_binary(tag) do
    case request_muni(%{command: "routeConfig", r: tag, terse: true}) do
      {:ok, %{"route" => %{"stop" => stops}}} when is_list(stops) -> {:ok, stops}
      {:ok, _} -> {:error, :unexpected_response}
      {:error, reason} -> {:error, reason}
    end
  end

  def stops_in_route!(tag) when is_binary(tag) do
    {:ok, result} = stops_in_route(tag)
    result
  end

  def request_muni(opts) when is_map(opts) do
    opts
    |> Map.put(:a, @agency)
    |> request()
  end

  def request_muni!(opts) when is_map(opts) do
    {:ok, result} = request_muni(opts)
    result
  end

  def request(opts) when is_map(opts) do
    with {:ok, %{body: body, status_code: 200}} <- HTTPoison.get(full_api_url(opts)),
         {:ok, result} when is_map(result) <- Jason.decode(body) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def request!(opts) when is_map(opts) do
    {:ok, result} = request(opts)
    result
  end

  defp full_api_url(opts) when is_map(opts) do
    encoded_opts = URI.encode_query(opts)

    @api_base_url
    |> URI.parse()
    |> Map.put(:query, encoded_opts)
    |> URI.to_string()
  end
end
