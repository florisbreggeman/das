defmodule Session.AccessControl do
  @moduledoc """
  Plug that can be used to guarantee that users are authenticated
  """

  defmodule NotLoggedInError do
    @moduledoc """
    Simple exception to throw in case the user isn't logged in
    """

    defexception message: "User was not logged in"
  end

  def init(options) do
    options
  end

  def call(conn, _opts) do
    path = conn.request_path
    #don't check access control in case the user is just trying to log in
    if path == "/session/login" or path == "/session/totp_login" do
      conn 
    else
      conn = Plug.Conn.fetch_session(conn)
      userid = Plug.Conn.get_session(conn, :userid)
      if userid == nil do
        conn
        |> Plug.Conn.put_resp_content_type("text/plain")
        |> Plug.Conn.send_resp(:forbidden, "You are not logged in")
        raise NotLoggedInError
      else
        conn
      end
    end
  end
end


