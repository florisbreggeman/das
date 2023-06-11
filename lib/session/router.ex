defmodule Session.Router do
  use Plug.Router

  import Ecto.Changeset

  @moduledoc """
  Main router for the session component.
  Mostly responsible for logging people in
  """

  plug Session.AccessControl

  plug :match
  plug :dispatch
  plug Plug.Parsers, parsers: [:json, :multipart], json_decoder: Jason

  get "/whoami" do
    userid = get_session(conn, :userid)
    user = Users.get_by_id(userid)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, Jason.encode!(user))
  end

  put "/whoami" do
    Util.basic_query(conn, [], fn conn, body -> 
      userid = get_session(conn, :userid)
      user = Users.get_by_id(userid)
      changeset = cast(user, body, [:name])
      repo = Storage.get()
      result = repo.update(changeset)
      case result do
        {:ok, user} -> 
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(:ok, Jason.encode!(user))
        _ -> 
          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(:server_error, inspect(result))
      end
    end)
  end

  put "/change_password" do
    Util.basic_query(conn, ["current_password", "new_password"], fn conn, body -> 
      userid = get_session(conn, :userid)
      user = Users.get_by_id(userid)
      if Bcrypt.verify_pass(Map.get(body, "current_password", ""), user.password) do
        changeset = cast(user, %{password: Bcrypt.hash_pwd_salt(Map.fetch!(body, "new_password"))}, [:password])
        repo = Storage.get()
        repo.update(changeset)
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:ok, "Changed password")
      else
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:forbidden, "Old password incorrect")
      end
    end)
  end


  post "/login" do
    Util.basic_query(conn, ["username", "password"], fn conn, body -> 
      user = Users.verify(Map.get(body, "username", ""), Map.get(body, "password", ""))
      if user != nil do
        conn
        |> fetch_session()
        |> put_session(:userid, user.id)
        |> put_session(:username, user.username)
        |> put_resp_content_type("text/plain")
        |> send_resp(:ok, "You are logged in!")
      else
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:forbidden, "Unknown username/password combination")
      end
    end)
  end

  post "/logout" do
    conn
    |> configure_session(drop: true)
    |> put_resp_content_type("text/plain")
    |> send_resp(:ok, "You have been logged out")
  end

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "Not Found")
  end

end
