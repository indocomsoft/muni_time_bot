defmodule MuniTimeBot.API.Prediction.Direction do
  @moduledoc """
  Provides an abstraction over a prediction direction in the NextBus API.
  """

  @enforce_keys ~w(title details)a
  defstruct @enforce_keys

  alias MuniTimeBot.API.Prediction.Detail

  @type t :: %__MODULE__{
          title: String.t(),
          details: [Detail.t()]
        }

  @spec new(any()) :: {:ok, t()} | {:error, any()}

  def new(api_raw = %{"prediction" => detail}) when is_map(detail) do
    new(%{api_raw | "prediction" => [detail]})
  end

  def new(%{"title" => title, "prediction" => details})
      when is_list(details) and is_binary(title) do
    details
    |> Enum.reduce_while([], fn raw_detail, acc ->
      case Detail.new(raw_detail) do
        {:ok, detail = %Detail{}} -> {:cont, [detail | acc]}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      details when is_list(details) ->
        {:ok, %__MODULE__{title: title, details: Enum.reverse(details)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def new(_) do
    {:error, __MODULE__}
  end
end
