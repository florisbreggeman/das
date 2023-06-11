defmodule Router do
  use Plug.Router

  import Plug.Conn

  @moduledoc """
  The main HTTP entrypoint for the program.
  Forwards subdirectories to their appropriate router
  """

  plug Plug.Session, store: :ets, key: "sid", table: :session

  forward "/session", to: Session.Router
  forward "/admin", to: Admin

  plug :match
  plug :dispatch
  
  get "/" do
    conn
    |> send_resp(:ok, "Hello, World!")
  end

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "Not Found")
  end

end

