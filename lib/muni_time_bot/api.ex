defmodule MuniTimeBot.API do
  @moduledoc """
  This module provides an abstraction of the NextBus API.
  """

  @api_base_url "http://webservices.nextbus.com/service/publicJSONFeed"
  @agency "sf-muni"

  require Logger

  @spec request_muni(map(), keyword()) ::
          {:ok, map()} | {:error, HTTPoison.Error.t() | Jason.DecodeError.t()}
  def request_muni(query, opts \\ []) when is_map(query) and is_list(opts) do
    query
    |> Map.put(:a, @agency)
    |> request(opts)
  end

  @spec request(map(), keyword()) ::
          {:ok, map()} | {:error, HTTPoison.Error.t() | Jason.DecodeError.t()}
  def request(query, opts \\ []) when is_map(query) and is_list(opts) do
    with {:ok, %{body: body, status_code: 200}} <- HTTPoison.get(full_api_url(query)),
         {:ok, result} when is_map(result) <- Jason.decode(body) do
      {:ok, result}
    else
      {:error, reason} ->
        if Keyword.get(opts, :retry) do
          Logger.info("#{__MODULE__}: retrying with query #{inspect(query)}")
          request(query, opts)
        else
          {:error, reason}
        end
    end
  end

  defp full_api_url(query) when is_map(query) do
    encoded_query = URI.encode_query(query)

    @api_base_url
    |> URI.parse()
    |> Map.put(:query, encoded_query)
    |> URI.to_string()
  end
end
