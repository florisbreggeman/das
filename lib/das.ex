defmodule Das do

  import Ecto.Query

  require Logger

  use Application

  @default_socket_location "tmp/das_util.sock"

  def start(_type, _args) do
    children = [
      Storage,
      {Plug.Cowboy, scheme: :http, plug: Router, options: [ip: Application.get_env(:das, :bind_ip, {127,0,0,1}), port: Application.get_env(:das, :bind_port, 8080)]},
      {LDAP.Socket, [ip: Application.get_env(:das, :bind_ip, {127,0,0,1}), port: Application.get_env(:das, :ldap_port, 389)]},
      {Registry, keys: :unique, name: OAuth.CodeRegistry},
      {Registry, keys: :unique, name: OAuth.TokenRegistry},
      {Registry, keys: :unique, name: Proxy.Registry}
    ]

    children = if Application.get_env(:das, :proxy_enable, false) do
      [ {Plug.Cowboy, scheme: :http, plug: Proxy.Router, options: [ip: Application.get_env(:das, :proxy_ip, {127,0,0,1}), port: Application.get_env(:das, :proxy_port, 9000)]} | children]
    else
      children
    end

    children = if Application.get_env(:das, :util_socket, false) do
      File.rm(Application.get_env(:das, :util_socket_location, @default_socket_location))
      [{Plug.Cowboy, scheme: :http, plug: Admin, options: [ip: {:local, Application.get_env(:das, :util_socket_location, @default_socket_location)}, port: 0]} | children]
    else
      children
    end

    opts = [strategy: :one_for_one, name: Das.Supervisor]

    #This line is required for the sessions to work
    :ets.new(:session, [:named_table, :public, read_concurrency: true])

    {:ok, supervisor} = Supervisor.start_link(children, opts)

    if Application.get_env(:das, :util_socket, false) do
      File.chmod(Application.get_env(:das, :util_socket_location, @default_socket_location), Application.get_env(:das, :util_socket_permissions, 200))
    end

    if Application.get_env(:das, :default_add, false) do
      repo = Storage.get()
      query = from u in Users.User, select: count(u.id)
      count = repo.one(query)
      if count == 0 do
        Logger.warning("User table empty; inserting default user")
        user = %Users.User{
          username: Application.get_env(:das, :default_username, "admin"),
          name: "Default User",
          email: Application.get_env(:das, :default_email, "admin@example.com"),
          admin: true,
          password: Bcrypt.hash_pwd_salt(Application.get_env(:das, :default_password, "badgers"))
        }
        repo.insert(user)
      end
    end


    #make sure we have the required encryption keys, generate otherwise
    OAuth.Key.ensure()

    #generate and store the signer and JWK after the keys have been created
    Supervisor.start_child(supervisor, {OAuth.IDToken.Signer, nil})
    Supervisor.start_child(supervisor, {OAuth.IDToken.JWK, nil})

    #ensure the proxy registry is filled from DB
    Proxy.Registry.populate()

    {:ok, supervisor}
  end

end
