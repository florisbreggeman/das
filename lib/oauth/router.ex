defmodule OAuth.Router do
  use Plug.Router

  import Plug.Conn

  @moduledoc """
  The router for OAuth 
  """

  plug NoCache

  plug :match
  plug :dispatch

  get "/authorize" do
    conn = fetch_session(conn)
    userid = get_session(conn, :userid)
    params = Plug.Conn.Query.decode(conn.query_string)
    client_id = Map.get(params, "client_id")
    client = Clients.get(client_id)
    response_types = Map.get(params, "response_type", "code") |> String.downcase() |> String.split()
    redirect = Map.get(params, "redirect_uri")
    redirect_object = Clients.get_callbackuri_object(client_id, redirect)
    state = Map.get(params, "state")
    scopes = Map.get(params, "scope", "openid") |> String.downcase() |> String.split()
    nonce = Map.get(params, "nonce")
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
      redirect_object == nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:bad_request, "This request uses  an unregistered callback URI. If you are the system administrator, please register the callback URI #{redirect} for the application #{client.name}")
      true ->
        case Enum.at(response_types, 0) do
          "code" ->
            code_data = %{client: client_id, redirect: redirect, user: userid, scope: scopes, nonce: nonce}
            code = OAuth.Code.generate(code_data)
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
    headers = Enum.reduce(conn.req_headers, %{}, fn {name, value}, acc -> Map.put(acc, name, value) end)
    body = case Map.get(headers, "content-type", "application/x-www-form-urlencoded") do
      "application/json" -> Jason.decode!(body) #this is not actually allowed under the standard, but we can try to work with it anyways
      _ -> Plug.Conn.Query.decode(body)
    end

    #verify the client first
    client_id = Map.get(body, "client_id")
    secret = Map.get(body, "client_secret")
    [client_id, secret] = if secret == nil and client_id == nil do 
      Map.get(headers, "authorization", "") |> String.split() |> Enum.at(1, "") |> Base.decode64! |> String.split(":")  #allow for authorization via HTTP headers if not provided in body
    else 
      [client_id, secret]
    end 
    if Clients.verify(client_id, secret) == nil do
      conn
      |> put_resp_content_type("text/plain")
      |> put_resp_header("WWW-Authenticate", "Basic")
      |> send_resp(:unauthorized, "Invalid client credentials")
    else
      case Map.get(body, "grant_type", "authorization_code") |> String.downcase() do
        _ -> #default: authorization_code
                  code = Map.get(body, "code")
          state = OAuth.Code.redeem(code)
          if state == nil do
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(:bad_request, Jason.encode!(%{error: "invalid_grant"}))
          else
            client_id_state = Map.get(state, :client)
            redirect_uri = Map.get(state, :redirect)
            user_id = Map.get(state, :user)
            scope = Map.get(state, :scope, ["openid"])
            cond do
              client_id_state != client_id ->
                conn
                |> put_resp_content_type("application/json")
                |> put_resp_header("WWW-Authenticate", "Basic")
                |> send_resp(:unauthorized, Jason.encode!(%{error: "invalid_client"}))
              redirect_uri != Map.get(body, "redirect_uri") -> #if redirect_uri was not present in this request and the access code request, both these values will be nil 
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(:bad_request, Jason.encode!{%{error: "invalid_grant", error_description: "Invalid Redirect URI"}})
              true ->
                token = OAuth.Token.generate(%{client: client_id, user: user_id, scope: scope})
  
                user = Users.get_by_id(user_id)
                claims = %{
                  sub: Integer.to_string(user_id),
                  aud: client_id,
                  iss: Application.get_env(:das, :oauth_scheme, "https://") <>  conn.host,
                  name: user.name,
                  email: user.email
                }
                nonce = Map.get(state, :nonce)
                claims = if nonce == nil do claims else Map.put(state, :nonce, nonce) end
                {:ok, id_token, _claims} = OAuth.IDToken.generate_and_sign(claims, OAuth.IDToken.get_signer())
  
                return = %{
                  access_token: token,
                  token_type: "Bearer",
                  expires_in: 4*60*60, #4 hours
                  scope: Enum.join(scope, " "),
                  id_token: id_token
                }
                conn
                |> put_resp_content_type("application/json")
                |> send_resp(:ok, Jason.encode!(return))
            end
          end
      end
    end
  end

  get "/userinfo" do
    {_, auth} = Enum.filter(conn.req_headers, fn {x, _} -> x == "authorization" end) |> Enum.at(0)
    {auth_type, auth_token} = if auth != nil do
      auth = String.split(auth)
      {Enum.at(auth, 0), Enum.at(auth, 1)}
    else
      {nil, nil}
    end
    case auth_type do
      "Bearer" -> 
        state = OAuth.Token.retrieve(auth_token)
        if state == nil do
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(:forbidden, Jason.encode!(%{error: "Token did not resolve"}))
        end
        user_id = Map.get(state, :user)
        user = Users.get_by_id(user_id)
        data = %{
          sub: Integer.to_string(user.id),
          preferred_username: user.username,
          name: user.name,
        }
        scopes = Map.get(state, :scope, [])
        data = if Enum.member?(scopes, "email") do Map.put(data, :email, user.email) else nil end
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:ok, Jason.encode!(data))
      _ -> 
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, Jason.encode!(%{error: "Invalid authorization type"}))
    end
  end

  get "/jwks" do
    claims = OAuth.IDToken.JWK.get()
    conn
    |> put_resp_content_type("application/jwk+json")
    |> send_resp(:ok, Jason.encode!(claims))
  end
end

