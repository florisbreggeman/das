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
      Admin.User.post(body)
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:ok, "Added user")
    end)
  end

  get "/user/:id" do
    user = Admin.User.get(id)
    {status, msg} = case user do
      nil -> {:not_found, "No user with id #{id}"}
      _ -> {:ok, Jason.encode!(user)}
    end
    conn
    |> put_resp_content_type("application/json")
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
          _ -> {:conflict, inspect(msg)}
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
      _ -> {:conflict, inspect(msg)}
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

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "not found")
  end
end
