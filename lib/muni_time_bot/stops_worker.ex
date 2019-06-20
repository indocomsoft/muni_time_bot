defmodule MuniTimeBot.StopsWorker do
  # 1 day
  @interval 86400 * 1000

  # 1 hour
  @retry_interval 3600 * 1000

  use GenServer

  alias MuniTimeBot.API.Stop

  @impl true
  def init(args) do
    case Stop.all_stops() do
      {:ok, stops} ->
        schedule_update()
        {:ok, stops}

      {:error, _} ->
        init(args)
    end
  end

  @impl true
  def handle_call(:get, _from, state) when is_list(state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:update, state) do
    case Stop.all_stops() do
      {:ok, stops} ->
        schedule_update()
        {:noreply, stops}

      {:error, _} ->
        schedule_update(@retry_interval)
        {:noreply, state}
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defp schedule_update(time \\ @interval) do
    Process.send_after(self(), :update, time)
  end

  # Client
  @spec all_stops :: [Stop.t()]
  def all_stops do
    GenServer.call(__MODULE__, :get)
  end
end
