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
    {:ok, body, conn} = read_body(conn)

    headers = conn.req_headers |> Enum.filter(fn {type, _value} ->
      type != "remote-user" and type != "remote-email" and type != "remote-name" and type != "host"
    end)
    headers = [{"host", domain} | [{"remote-user", user.username} | [ {"remote-email", user.email} | [ {"remote-name", user.name} | headers ]]]]

    {:ok, req} = Mint.HTTP1.connect(scheme, domain, port)
    join_char = if conn.query_string == "" do "" else "?" end
    query = conn.request_path <> join_char <> conn.query_string
    {:ok, req, _ref} = Mint.HTTP1.request(req, conn.method, query, headers, body)
    http_receive(req, conn)
  end

  _doc = """
  This function is responsible for receiving the messages from the outgoing connection, and passing them on to Plug (the incoming connection) as quickly as possible.
  In order to do this, it uses the Plug chunked encoding; this allows data from the outgoing connection to be passed along immediately.
  """
  defp http_receive(req, conn, status_code \\ :server_error) do
    #Firstly, we wait for any incoming messages
    receive do
      message ->
        #What we do with this message depends on what the Mint parses makes of it.
        case Mint.HTTP.stream(req, message) do
          #If the Mint parses throws an error, we throw a bad gateway back to the user.
          {:error, _req, reason, _responses} -> conn
          |> put_resp_content_type("text/plain")
          |> send_resp(:bad_gateway, "Error while handling proxy connection: " <> inspect(reason))
          #Parse any correct messages:
          {:ok, req, responses} ->
            #We go through all responses in this message, and reduce them to the connection object
            {action, conn, status_code} = Enum.reduce(responses, {:continue, conn, status_code}, fn response, {action, conn, status_code} ->
              {action, conn, status_code} = case response do
                #Mint usually puts the status code before the headers
                #Plug, on the other hand, must have the headers before it will accept a status code.
                #To solve this, we don't apply the status code to the conn; instead, we store it in a value, and use the action property to determine when we should send it
                #Note that we only do this when parsing the responses from a single message; if the headers arrive in a separate message after the status code, the code crashes. Fortunately, this should never be the case.
                {:status, _ref, status_code} -> {action, conn, status_code}
                #Now that we have all the headers, we will allow the connection to be sent
                {:headers, _ref, headers} -> {:send, Enum.filter(headers, fn {name, _value} -> name != "transfer-encoding" end) |> Enum.reduce(conn, fn {name, value}, conn -> put_resp_header(conn, name, value) end), status_code}
                #If we get a data message, we send it over as a chunk
                #Note that this assumes the status code has already been parsed
                {:data, _ref, data} -> 
                  {:ok, conn} = chunk(conn, data)
                  {action, conn, status_code}
                #If we are done, we set the action to done, so we will stop receiving new messages
                {:done, _ref} -> {:done, conn, status_code}
                {:error, _ref, reason} -> 
                  #try to report the error back to the client; if this is not possible because the status code was already sent, try to proxy the error along to the client by suddenly halting the connection.
                  try do
                    {:done, send_resp(conn, :bad_gateway, "The gateway send a bad response: " <> inspect(reason)), :bad_gateway}
                  rescue
                    Plug.Conn.AlreadySentError -> {:done, conn, :bad_gateway}
                  end
                #if we somehow receive another type of stream message, close the connection and pretend nothing happened
                _ -> {:done, conn, :bad_gateway}

              end
                if action == :send do
                  {:continue, send_chunked(conn, status_code), status_code}
                else
                  {action, conn, status_code}
                end
            end)
            case action do
              :continue -> 
                http_receive(req, conn, status_code)
              :send -> 
                conn = send_chunked(conn, status_code)
                http_receive(req, conn, status_code)
              _ -> 
                conn #includes :done
            end
            #if we get an unrelated message, we ignore it
            #the message is most likely Plug informing us we have successfully sent a chunk
            _ -> http_receive(req, conn, status_code) 
        end
        after 5000 -> 
        #if we have not received a :done after 5 seconds, we simply return the connection as-is
        conn 
    end
  end
end

