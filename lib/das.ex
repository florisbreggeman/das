defmodule Das do

  require Logger

  use Application

  def start(_type, _args) do
    children = [
      Storage
    ]

    opts = [strategy: :one_for_one, name: Das.Supervisor]

    {:ok, _supervisor} = Supervisor.start_link(children, opts)
  end

end
