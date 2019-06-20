defmodule MuniTimeBot.API.Prediction.Detail do
  @moduledoc """
  Provides an abstraction over a prediction detail in the NextBus API.
  """

  @enforce_keys ~w(minutes seconds epoch_time is_departure is_schedule_based is_delayed)a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          minutes: integer(),
          seconds: integer(),
          epoch_time: integer(),
          is_departure: boolean(),
          is_schedule_based: boolean(),
          is_delayed: boolean()
        }

  @spec new(any()) :: {:ok, t()} | {:error, __MODULE__}
  def new(raw_api = %{"minutes" => minutes, "seconds" => seconds, "epochTime" => epoch_time})
      when is_binary(minutes) and is_binary(seconds) and is_binary(epoch_time) do
    with {integer_minutes, _} <- Integer.parse(minutes),
         {integer_seconds, _} <- Integer.parse(seconds),
         {integer_epoch_time, _} <- Integer.parse(epoch_time) do
      is_departure = parse_boolean(raw_api["isDeparture"])
      is_schedule_based = parse_boolean(raw_api["isScheduleBased"])
      is_delayed = parse_boolean(raw_api["delayed"])

      {:ok,
       %__MODULE__{
         minutes: integer_minutes,
         seconds: integer_seconds,
         epoch_time: integer_epoch_time,
         is_departure: is_departure,
         is_schedule_based: is_schedule_based,
         is_delayed: is_delayed
       }}
    else
      :error -> {:error, __MODULE__}
    end
  end

  def new(_) do
    {:error, __MODULE__}
  end

  @spec parse_boolean(String.t()) :: boolean()
  defp parse_boolean("true"), do: true
  defp parse_boolean(_), do: false
end
