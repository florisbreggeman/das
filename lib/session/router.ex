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
      changeset = cast(user, body, [:name, :totp_ldap])
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
        if user.totp_secret == nil do
          conn
          |> fetch_session()
          |> put_session(:userid, user.id)
          |> put_session(:username, user.username)
          |> put_resp_content_type("text/plain")
          |> send_resp(:ok, "You are logged in!")
        else
          conn
          |> fetch_session()
          |> put_session(:tentative_userid, user.id)
          |> put_resp_content_type("text/plain")
          |> send_resp(:accepted, "Awaiting TOTP")
        end
      else
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:forbidden, "Unknown username/password combination")
      end
    end)
  end

  post "/totp_login" do
    Util.basic_query(conn, ["code"], fn conn, body ->
      code = Map.get(body, "code")
      conn = fetch_session(conn)
      userid = get_session(conn, :tentative_userid)
      user = Users.get_by_id(userid)
      if NimbleTOTP.valid?(user.totp_secret, code) do
        conn
        |> put_session(:userid, user.id)
        |> put_session(:username, user.username)
        |> put_resp_content_type("text/plain")
        |> send_resp(:ok, "You are logged in!")
      else
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:forbidden, "Incorrect code")
      end
    end)
  end


  post "/logout" do
    conn
    |> configure_session(drop: true)
    |> put_resp_content_type("text/plain")
    |> send_resp(:ok, "You have been logged out")
  end

  get "/totp" do
    userid = get_session(conn, :userid)
    user = Users.get_by_id(userid)
    if user.totp_secret == nil do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:not_found, "TOTP is not enabled")
    else
      totp_url = NimbleTOTP.otpauth_uri("DAS:"<>user.username, user.totp_secret, issuer: Application.get_env(:das, :home, "DAS"))
      svg = EQRCode.encode(totp_url) |> EQRCode.svg()
      conn
      |> put_resp_content_type("image/svg+xml")
      |> send_resp(:ok, svg)
    end
  end

  post "/totp" do
    userid = get_session(conn, :userid)
    user = Users.get_by_id(userid)
    if user.totp_secret == nil do
      secret = NimbleTOTP.secret()
      repo = Storage.get()
      Ecto.Changeset.cast(user, %{totp_secret: secret}, [:totp_secret])
      |> repo.update()
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:ok, "Enabled TOTP")
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:conflict, "TOTP is already enabled")
    end
  end

  delete "/totp" do
    userid = get_session(conn, :userid)
    user = Users.get_by_id(userid)
    if user.totp_secret == nil do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(:conflict, "TOTP is already disabled")
    else
      repo = Storage.get()
      Ecto.Changeset.cast(user, %{totp_secret: nil}, [:totp_secret])
      |> repo.update()
      conn
      |> put_resp_content_type("tex/plain")
      |> send_resp(:ok, "Disabled TOTP")
    end
  end
  

  match _ do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(404, "Not Found")
  end

end
