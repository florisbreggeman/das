defmodule Forward.Router do
  use Plug.Router

  import Plug.Conn

  require Logger

  @moduledoc """
  The router for handling regular reverse-proxy authentication requests
  """

  plug NoCache

  plug :match
  plug :dispatch

  get "create_session" do
    conn = fetch_session(conn)
    userid = get_session(conn, :userid)
    params = Plug.Conn.Query.decode(conn.query_string)
    scheme = Map.get(params, "scheme", "https://")
    host = Map.get(params, "host")
    uri = Map.get(params, "uri", "/")
    client = if host == nil do nil else Clients.get_by_name(host) end
    cond do
      host == nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:bad_request, "The X-Forwarded-Host parameter was not found.\r\nIf you are the system administrator, please verify your Reverse Proxy configuration")
      client == nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:internal_server_error, "The domain #{host} is not a registered reverse-proxy client.\r\nIf you are the system administrator and the domain should belong to a reverse-proxy authenticated website, please register a reverse-proxy application with this domain")
      userid == nil -> #we redirect to the login portal
        current_url = "forward_auth/create_session?scheme=#{scheme}&host="<>URI.encode_www_form(host)<>"&uri="<>URI.encode_www_form(uri)
        conn
        |> put_resp_header("location", "../login.html?redirect="<>URI.encode_www_form(current_url))
        |> send_resp(:found, "")
      true -> 
        state = %{
          scheme: scheme,
          host: host,
          uri: uri,
          userid: userid
        }
        code = OAuth.Code.generate(state)
        join_char = if String.contains?(uri, "?") do "&" else "?" end
        conn
        |> put_resp_header("location", "#{scheme}://#{host}#{uri}#{join_char}code=#{code}")
        |> send_resp(:found, "")
    end
  end

  match _ do
    conn = fetch_session(conn)
    userid = get_session(conn, :userid)
    headers = Enum.reduce(conn.req_headers, %{}, fn {header, value}, acc -> Map.put(acc, header, value) end)
    scheme = Map.get(headers, "x-forwarded-proto", "https")
    host = Map.get(headers, "x-forwarded-host")
    uri = Map.get(headers, "x-forwarded-uri", "/")
    forwarded_for = Map.get(headers, "x-forwarded-for")
    real_ip = Map.get(headers, "x-real-ip")
    if userid == nil do
      params = Plug.Conn.Query.decode(conn.query_string)
      code = if Map.get(params, "code") == nil do
        matches = Regex.run(~r/\?([^?]*)/, uri)
        if matches != nil do
          params = Enum.at(matches, 1) |> Plug.Conn.Query.decode()
          Map.get(params, "code")
        end
      else
        Map.get(params, "code")
      end
      if code == nil do
        IO.inspect(headers)
        #no user id, and no code; that's an unauthenticated request, let Nginx handle the redirect
        conn
        |> send_resp(:unauthorized, "")
      else
        #try to parse the received authorization code
        state = OAuth.Code.redeem(code)
        if state == nil do
          #code doesn't parse, return an error
          Logger.debug("Forward auth: Authorization code #{code} did not parse")
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(:unauthorized, "Invalid authorization code")
        else
          #verify that the data in the code state equal the received headers
          if Enum.all?([scheme: scheme, host: host], fn {key, value} -> Map.get(state, key) == value end) do
          #code parses, put everything in the session and return ok
            userid = Map.get(state, :userid)
            user = Users.get_by_id(userid)
            conn
            |> put_session(:userid, userid)
            |> put_session(:user, user)
            |> put_session(:scheme, scheme)
            |> put_session(:host, host)
            |> put_session(:forwarded_for, forwarded_for)
            |> put_session(:real_ip, real_ip)
            |> put_resp_header("remote-user", user.username)
            |> put_resp_header("remote-email", user.email)
            |> send_resp(:ok, "")
          else
            Logger.debug("Forward auth: Authorization code #{code} found mismatch between original request and redirected request; scheme = {#{scheme}, "<>Map.get(state, :scheme, "nil")<>"}, host = {#{host}, "<>Map.get(state, :host, "nil")<>"}")
            conn
            |> put_resp_content_type("text/plain")
            |> send_resp(:unauthorized, "Authorization code does not correlate with this request URI")
          end
        end
      end
    else
      #there's already a session with a userid, verify that the data in the session matches the received headers
      #Line below generates a list of tuples matching atoms referring to the session data to a header value (in a variable), and checks if they are all the same
      if Enum.all?([scheme: scheme, host: host, forwarded_for: forwarded_for, real_ip: real_ip], fn {key, value} -> get_session(conn, key) == value end) do
        user = get_session(conn, :user)
        conn
        |> put_resp_header("remote-user", user.username)
        |> put_resp_header("remote-email", user.email)
        |> send_resp(:ok, "")
      else
        if ip_version_mismatch(real_ip, get_session(conn, :real_ip)) do
          #In cases where the client decides to use ip4 for contacting the client app but ip6 for contacting the login portal, we have a justified ip mismatch and we can't verify it.
          user = get_session(conn, :user)
          conn
          |> put_resp_header("remote-user", user.username)
          |> put_resp_header("remote-email", user.email)
          |> send_resp(:ok, "")
        else 
          Logger.debug("Forward auth: session for userid #{userid} does not match received headers\r\n" <> Kernel.inspect(headers) <> "\r\n\r\n" <> Kernel.inspect(get_session(conn)))
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(:unauthorized, "Session data does not match received headers")
        end
      end
    end
  end

  defp ip_version_mismatch(ip1, ip2) do
    (String.contains?(ip1, ":") and String.contains?(ip2, ".")) or (String.contains?(ip1, ".") and String.contains?(ip2, ":"))
  end

end

