defmodule OAuth.Router do
  use Plug.Router

  import Plug.Conn

  @moduledoc """
  The router for OAuth 
  """

  plug :match
  plug :dispatch

  get "/authorize" do
    conn = fetch_session(conn)
    userid = get_session(conn, :userid)
    params = Plug.Conn.Query.decode(conn.query_string)
    client_id = Map.get(params, "client_id")
    client = Clients.get(client_id)
    #TODO verify redirect url
    response_types = Map.get(params, "response_type", "code") |> String.downcase() |> String.split()
    redirect = Map.get(params, "redirect_uri")
    state = Map.get(params, "state")
    #TODO do something with scopes
    _scopes = Map.get(params, "scopes", "user") |> String.downcase() |> String.split()
    cond do
      userid == nil ->
        our_uri = "oauth/authorize?" <> conn.query_string
        params = Plug.Conn.Query.encode(%{redirect: our_uri})
        conn
        |> put_resp_header("location", "../login.html?" <> params)
        |> send_resp(:found, "")
      client == nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:forbidden, "This client ID is unknown. Contact your system administrator")
      redirect == nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:bad_request, "No Redirect URI parameter in request")
      true ->
        case Enum.at(response_types, 0) do
          "code" ->
            code = OAuth.Code.generate(client_id)
            response_params = %{
              code: code
            }
            response_params = if state != nil do Map.put(response_params, :state, state) else response_params end
            join_char = if String.contains?(redirect, "?") do "&" else "?" end
            redirect = redirect <> join_char <> Plug.Conn.Query.encode(response_params)
            conn
            |> put_resp_header("location", redirect)
            |> send_resp(:found, "")
          _ -> 
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(:method_not_allowed, "Response type is not (yet) supported")
        end
    end
  end

  post "/token" do
    {:ok, body, conn} = read_body(conn)
    IO.inspect(body)
    IO.inspect(conn.req_headers)
    IO.inspect(conn.query_string)
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:ok, "yay")
  end

end

