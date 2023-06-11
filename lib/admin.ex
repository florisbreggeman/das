defmodule Admin do
  use Plug.Router

  plug Session.AdminControl

  plug :match
  plug :dispatch

  get "/user" do
    users = Admin.User.get()
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, Jason.encode!(users))
  end

  post "/user" do
    Util.basic_query(conn, ["username", "email", "password"], fn conn, body -> 
      {status, msg} = Admin.User.post(body)
      {status, msg} = case status do
        :ok -> {:ok, "Added user"}
        _ -> {:conflict, Util.parse_ecto_error(msg)}
      end
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    end)
  end

  get "/user/:id" do
    user = Admin.User.get(id)
    {status, msg, content_type} = case user do
      nil -> {:not_found, "No user with id #{id}", "text/plain"}
      _ -> {:ok, Jason.encode!(user), "application/json"}
    end
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, msg)
  end

  put "/user/:id" do
    Util.basic_query(conn, [], fn conn, body ->
      if not Map.get(body, "admin", true) and String.to_integer(id) == get_session(conn, :userid)  do
        conn 
        |> put_resp_content_type("text/plain")
        |> send_resp(:conflict, "Can't change own admin status")
      else
        {status, msg} = Admin.User.put(id, body)
        {status, msg} = case status do
          :ok -> {:ok, "Updated user"}
          :not_found -> {status, msg}
          _ -> {:conflict, Util.parse_ecto_error(msg)}
        end
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(status, msg)
      end
    end)
  end
  
  delete "/user/:id" do
    {status, msg} = Admin.User.delete(id)
    {status, msg} = case status do
      :ok -> {:ok, "Deleted user"}
      :not_found -> {:not_found, msg}
      _ -> {:conflict, Util.parse_ecto_error(msg)}
    end
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(status, msg)
  end

  put "/user/:id/change_password" do
    new_password = Admin.User.change_password(id)
    if new_password == nil do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:not_found, "No user with id #{id}")
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:ok, Jason.encode!(%{password: new_password}))
    end
  end

  get "/client" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, Jason.encode!(Clients.get_all()))
  end

  post "/client" do
    Util.basic_query(conn, ["name", "url"], fn conn, body -> 
      {status, msg} = Admin.Client.post(body)
      {status, msg} = case status do
        :ok -> {:ok, "Added client"}
        _ -> {:conflict, Util.parse_ecto_error(msg)}
      end
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    end)
  end

  get "/client/:id" do
    client = Admin.Client.get(id)
    {status, msg, content_type} = case client do
      nil -> {:not_found, "No client with id #{id}", "text/plain"}
      _ -> {:ok, Jason.encode!(client), "application/json"}
    end
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, msg)
  end

  put "/client/:id" do
    Util.basic_query(conn, [], fn conn, body ->
      {status, msg} = Admin.Client.put(id, body)
      {status, msg} = case status do
        :ok -> {:ok, "Updated client"}
        :not_found -> {status, msg}
        _ -> {:conflict, Util.parse_ecto_error(msg)}
      end
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    end)
  end
  
  delete "/client/:id" do
    {status, msg} = Admin.Client.delete(id)
    {status, msg} = case status do
      :ok -> {:ok, "Deleted client"}
      :not_found -> {:not_found, msg}
      _ -> {:conflict, Util.parse_ecto_error(msg)}
    end
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(status, msg)
  end

  get "/client/:id/credentials" do
    data = Admin.Client.credentials(id)
    {status, msg, content_type} = case data do
      nil -> {:not_found, "No client with id #{id}", "text/plain"}
      _ -> {:ok, Jason.encode!(data), "application/json"}
    end
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, msg)
  end

  get "/client/:id/callbacks" do
    data = Admin.Client.get_callbackuris(id)
    {status, msg, content_type} = case data do
      nil -> {:not_found, "Invalid ID format", "text/plain"}
      _ -> {:ok, Jason.encode!(data), "application/json"}
    end
    conn
    |> put_resp_content_type(content_type)
    |> send_resp(status, msg)
  end

  post "/client/:id/callbacks" do
    Util.basic_query(conn, ["uri"], fn conn, body ->
      uri = Map.get(body, "uri")
      {status, msg} = Admin.Client.post_callbackuri(id, uri)
      {status, msg} = case status do
        :ok -> {:ok, "Added callback uri"}
        :not_found -> {status, msg}
        _ -> {:conflict, Util.parse_ecto_error(msg)}
      end
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    end)
  end

  delete "/client/:id/callbacks" do
    Util.basic_query(conn, ["uri"], fn conn, body ->
      uri = Map.get(body, "uri")
      {status, msg} = Admin.Client.delete_callbackuri(id, uri)
      {status, msg} = case status do
        :ok -> {:ok, "Deleted callback URI"}
        :not_found -> {:not_found, msg}
        _ -> {:conflict, Util.parse_ecto_error(msg)}
      end
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    end)
  end

  get "/client_ldap_area" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:ok, Application.get_env(:das, :ldap_client_area, "ou=clients,dc=das,dc=nl"))
  end

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "not found")
  end
end
