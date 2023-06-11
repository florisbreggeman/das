defmodule Session.Router do
  use Plug.Router

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
    |> send_resp(:ok, Jason.encode!(%{
      username: user.username,
      email: user.email,
      given_names: user.given_names,
      family_name: user.family_name,
      admin: user.admin
    }))
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
