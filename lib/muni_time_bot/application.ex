defmodule MuniTimeBot.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    token = ExGram.Config.get(:ex_gram, :token)

    children = [
      ExGram,
      {MuniTimeBot, [method: :polling, token: token]},
      MuniTimeBot.StopsWorker
    ]

    opts = [strategy: :one_for_one, name: MuniTimeBot.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
