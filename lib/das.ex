defmodule Das do

  require Logger

  use Application

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

    opts = [strategy: :one_for_one, name: Das.Supervisor]

    #This line is required for the sessions to work
    :ets.new(:session, [:named_table, :public, read_concurrency: true])

    {:ok, supervisor} = Supervisor.start_link(children, opts)

    #just to easily populate the db
    repo = Storage.get()
    user = %Users.User{
      username: "floris",
      name: "Floris Tenzin",
      email: "info@sfbtech.nl",
      admin: true,
      password: Bcrypt.hash_pwd_salt("admin")
    }
    #repo.insert(user)

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
