defmodule Session.AdminControl do
  @moduledoc """
  Plug that can be used to guarantee that users are admin
  """

  defmodule NotLoggedInError do
    @moduledoc """
    Simple exception to throw in case the user isn't logged in
    """

    defexception message: "User was not logged in"
  end

  defmodule NotAdminError do
    @moduledoc """
    Simple exception to throw in case the user isn't logged in
    """

    defexception message: "User tried to access administrative endpoint with non-admin account"
  end

  def init(options) do
    options
  end

  def call(conn, opts) do
    #This function only checks if the requests comes from the utility socket, actual logic is handled by process
    #We check for the socket by two methods: firstly, we check if the host is localhost. Secondly, we check that the path does not start with /admin
    if conn.host == "localhost" do
      start = String.slice(conn.request_path, 0, 6)
      if start == "/admin" do
        process(conn, opts)
      else
        conn
      end
    else
      process(conn, opts)
    end
  end

  def process(conn, _opts) do
    path = conn.request_path
    #don't check access control in case the user is just trying to log in
    if path == "/login" do
      conn 
    else
      conn = Plug.Conn.fetch_session(conn)
      userid = Plug.Conn.get_session(conn, :userid)
      if userid == nil do
        conn
        |> Plug.Conn.put_resp_content_type("text/plain")
        |> Plug.Conn.send_resp(:forbidden, "User was not logged in")
        raise NotLoggedInError
      else
        user = Users.get_by_id(userid)
        if user.admin do
          conn
        else
          conn
          |> Plug.Conn.put_resp_content_type("text/plain")
          |> Plug.Conn.send_resp(:forbidden, "You must be an administrator to use this endpoint")
          raise NotAdminError
        end
      end
    end
  end
end


