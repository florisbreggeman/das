defmodule Router do
  use Plug.Router

  import Plug.Conn

  @moduledoc """
  The main HTTP entrypoint for the program.
  Forwards subdirectories to their appropriate router
  """

  plug Plug.Static, at: "/", from: :das

  plug Plug.Session, store: Session, key: "sid", registry: Session.Registry

  forward "/session", to: Session.Router
  forward "/admin", to: Admin
  forward "/oauth", to: OAuth.Router
  forward "/forward_auth", to: Forward.Router

  plug :match
  plug :dispatch
  
  get "/" do
    conn = Plug.Conn.fetch_session(conn)
    location = if Plug.Conn.get_session(conn, :userid) == nil do
      "login.html"
    else
      "index.html"
    end
    conn
    |> put_resp_header("location", location)
    |> send_resp(:found, "")
  end

  get "/.well-known/openid-configuration" do
    issuer = Application.get_env(:das, :oauth_scheme, "https://") <> conn.host
    claims = %{
      "issuer" => issuer,
      "authorization_endpoint" => issuer <> "/oauth/authorize",
      "token_endpoint" => issuer <> "/oauth/token",
      "userinfo_endpoint" => issuer <> "/oauth/userinfo",
      "jwks_uri" => issuer <> "/oauth/jwks",
      "scopes_supported" => ["openid", "email"],
      "response_types_supported" => ["code"], #TODO expand
      "grant_types_supported" => ["authorization_code"], #TODO expand?
      "subject_types_supported" => ["public"], #TODO expand
      "id_token_signing_alg_values_supported" => ["RS256"],
    }
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, Jason.encode!(claims))
  end

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "Not Found")
  end

end

