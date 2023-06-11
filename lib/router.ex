defmodule Router do
  use Plug.Router

  import Plug.Conn

  @moduledoc """
  The main HTTP entrypoint for the program.
  Forwards subdirectories to their appropriate router
  """

  plug :match
  plug :dispatch

  plug Plug.Session, store: :ets, key: "sid", table: :session

  #forward "/admin", to: Router.Admin
  
  get "/" do
    conn
    |> send_resp(:ok, "Hello, World!")
  end
end

