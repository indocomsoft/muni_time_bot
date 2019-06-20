defmodule MuniTimeBot.API.Prediction.Direction do
  @enforce_keys ~w(title details)a
  defstruct @enforce_keys

  alias MuniTimeBot.API.Prediction.Detail

  @type t :: %__MODULE__{
          title: String.t(),
          details: [Detail.t()]
        }

  @spec new(any()) :: {:ok, t()} | {:error, any()}

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

  def new(%{"title" => title, "prediction" => detail}) when is_map(detail) and is_binary(title) do
    case Detail.new(detail) do
      {:ok, detail = %Detail{}} -> {:ok, %__MODULE__{title: title, details: [detail]}}
      {:error, reason} -> {:error, reason}
    end
  end

  def new(_) do
    {:error, __MODULE__}
  end
end
