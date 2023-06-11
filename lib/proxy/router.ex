defmodule Proxy.Router do
  import Plug.Conn
  @moduledoc """
  The socket handler entrypoint for proxy auth
  """

  def init(_opts) do
    Plug.Session.init([store: :ets, key: "sid", table: :session])
  end

  def call(conn, opts) do
    conn = Plug.Session.call(conn, opts)
    conn = fetch_session(conn)
    user = get_session(conn, :user)
    if user == nil do
      params = Plug.Conn.Query.decode(conn.query_string)
      code = Map.get(params, "code", "")
      state = OAuth.Code.redeem(code)
      userid = if state == nil do nil else Map.get(state, :userid) end
      if userid == nil do
        join_char = if conn.query_string == "" do "" else "?" end
        uri = conn.request_path <> join_char <> conn.query_string
        conn
        |> put_resp_header("location", Application.get_env(:das, :home, "https://das.dev.local") <> "/forward_auth/create_session?scheme="<>Atom.to_string(conn.scheme)<>"&host="<>URI.encode_www_form(conn.host)<>"&uri="<>URI.encode_www_form(uri))
        |> send_resp(:found, "")
      else
        user = Users.get_by_id(userid)
        conn = put_session(conn, :user, user)
        get_host(conn, opts, user)
      end
    else
      get_host(conn, opts, user)
    end
  end

  def get_host(conn, opts, user) do
    destination = Proxy.Registry.get(conn.host)
    if destination == nil do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:not_found, "DAS is not aware of a host by this name")
    else
      request(conn, opts, user, destination)
    end
  end


  def request(conn, _opts, user, destination) do
    {scheme, domain, port} = destination
    query = if conn.query_string == "" do
      conn.request_path
    else
      conn.request_path <> "?" <> conn.query_string
    end
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:ok, "yay\r\n"<>query<>"\r\n"<>Atom.to_string(scheme)<>"\r\n"<>domain<>"\r\n"<>Integer.to_string(port)<>"\r\n"<>Jason.encode!(user))
  end

end

