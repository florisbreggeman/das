defmodule NoCache do
  @moduledoc """
  Plug that adds some HTTP headers against caching.
  Mandated for some OAuth endpoints by specification.
  """

  def init(options) do
    options
  end

  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_header("cache-control", "no-store")
    |> Plug.Conn.put_resp_header("pragma", "no-cache")
  end
end


